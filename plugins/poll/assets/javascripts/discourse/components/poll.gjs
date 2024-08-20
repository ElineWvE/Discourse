import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import round from "discourse/lib/round";
import icon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import I18n from "discourse-i18n";
import PollBreakdownModal from "../components/modal/poll-breakdown";
import {
  MULTIPLE_POLL_TYPE,
  PIE_CHART_TYPE,
  REGULAR_POLL_TYPE,
} from "../components/modal/poll-ui-builder";
import PollButtonsDropdown from "../components/poll-buttons-dropdown";
import PollInfo from "../components/poll-info";
import PollOptions from "../components/poll-options";
import PollResultsPie from "../components/poll-results-pie";
import PollResultsTabs from "../components/poll-results-tabs";

const FETCH_VOTERS_COUNT = 25;
const STAFF_ONLY = "staff_only";
const MULTIPLE = "multiple";
const NUMBER = "number";
const REGULAR = "regular";
const RANKED_CHOICE = "ranked_choice";
const ON_VOTE = "on_vote";
const ON_CLOSE = "on_close";
const CLOSED_STATUS = "closed";
const OPEN_STATUS = "open";

export default class PollComponent extends Component {
  @service currentUser;
  @service siteSettings;
  @service router;
  @service appEvents;
  @service dialog;
  @service modal;

  @tracked vote = this.args.attrs.vote || [];
  @tracked poll = this.args.attrs.poll;
  @tracked preloadedVoters = this.defaultPreloadedVoters();
  @tracked voterListExpanded = false;
  @tracked hasSavedVote = this.args.attrs.hasSavedVote;

  @tracked
  showResults =
    !(this.poll.results === ON_CLOSE && !this.closed) &&
    (this.hasSavedVote ||
      (this.topicArchived && !this.staffOnly) ||
      (this.closed && !this.staffOnly));

  @tracked showTally = false;

  checkUserGroups = (user, poll) => {
    const pollGroups =
      poll && poll.groups && poll.groups.split(",").map((g) => g.toLowerCase());

    if (!pollGroups) {
      return true;
    }

    const userGroups =
      user && user.groups && user.groups.map((g) => g.name.toLowerCase());

    return userGroups && pollGroups.some((g) => userGroups.includes(g));
  };

  areRanksValid = (arr) => {
    let ranks = new Set(); // Using a Set to keep track of unique ranks
    let hasNonZeroDuplicate = false;

    arr.forEach((obj) => {
      const rank = obj.rank;

      if (rank !== 0) {
        if (ranks.has(rank)) {
          hasNonZeroDuplicate = true;
          return; // Exit forEach loop if a non-zero duplicate is found
        }
        ranks.add(rank);
      }
    });

    return !hasNonZeroDuplicate;
  };

  _toggleOption = (option, rank = 0) => {
    if (this.isMultiple) {
      const chosenIdx = this.vote.indexOf(option.id);

      if (chosenIdx !== -1) {
        this.vote.splice(chosenIdx, 1);
      } else {
        this.vote.push(option.id);
      }
    } else if (this.isRankedChoice) {
      this.options.forEach((candidate) => {
        const chosenIdx = this.vote.findIndex(
          (object) => object.digest === candidate.id
        );

        if (chosenIdx === -1) {
          this.vote.push({
            digest: candidate.id,
            rank: candidate.id === option ? rank : 0,
          });
        } else {
          if (candidate.id === option) {
            this.vote[chosenIdx].rank = rank;
          }
        }
      });
    } else {
      this.vote = [option.id];
    }

    this.vote = [...this.vote];
  };

  defaultPreloadedVoters() {
    const preloadedVoters = {};

    if (this.poll.public && this.args.preloadedVoters) {
      Object.keys(this.args.preloadedVoters).forEach((key) => {
        preloadedVoters[key] = {
          voters: this.args.preloadedVoters[key],
          loading: false,
        };
      });
    }

    this.options.forEach((option) => {
      if (!preloadedVoters[option.id]) {
        preloadedVoters[option.id] = {
          voters: [],
          loading: false,
        };
      }
    });

    return preloadedVoters;
  }

  get id() {
    return this.args.attrs.id;
  }

  get post() {
    return this.args.attrs.post;
  }

  get groupableUserFields() {
    return this.args.attrs.groupableUserFields;
  }

  get isStaff() {
    return this.currentUser?.staff;
  }

  get titleHTML() {
    return htmlSafe(this.args.attrs.titleHTML);
  }

  get topicArchived() {
    return this.post.get("topic.archived");
  }

  get isRankedChoice() {
    return this.poll.type === RANKED_CHOICE;
  }

  get staffOnly() {
    return this.poll.results === STAFF_ONLY;
  }

  get isMultiple() {
    return this.poll.type === MULTIPLE;
  }

  get isNumber() {
    return this.poll.type === NUMBER;
  }

  get isMe() {
    return this.currentUser && this.post.user_id === this.currentUser.id;
  }

  get status() {
    return this.poll.get("status");
  }

  @action
  async castVotes(option) {
    if (!this.canCastVotes) {
      return;
    }

    if (!this.currentUser) {
      return;
    }

    try {
      const poll = await ajax("/polls/vote", {
        type: "PUT",
        data: {
          post_id: this.post.id,
          poll_name: this.poll.name,
          options: this.vote,
        },
      });

      this.hasSavedVote = true;
      this.poll.setProperties(poll);
      this.appEvents.trigger("poll:voted", poll, this.post, this.vote);

      if (this.poll.results !== ON_CLOSE) {
        this.showResults = true;
      }

      if (this.poll.results === STAFF_ONLY) {
        if (this.currentUser && this.currentUser.staff) {
          this.showResults = true;
        } else {
          this.showResults = false;
        }
      }
    } catch (error) {
      if (error) {
        if (!this.isMultiple && !this.isRankedChoice) {
          this._toggleOption(option);
        }
        popupAjaxError(error);
      } else {
        this.dialog.alert(I18n.t("poll.error_while_casting_votes"));
      }
    }
  }

  get options() {
    let enrichedOptions = this.poll.get("options");

    if (this.isRankedChoice) {
      enrichedOptions.forEach((candidate) => {
        const chosenIdx = this.vote.findIndex(
          (object) => object.digest === candidate.id
        );
        if (chosenIdx === -1) {
          candidate.rank = 0;
        } else {
          candidate.rank = this.vote[chosenIdx].rank;
        }
      });
    }

    return enrichedOptions;
  }

  get voters() {
    return this.poll.get("voters");
  }

  get rankedChoiceOutcome() {
    return this.poll.get("ranked_choice_outcome") || [];
  }

  get min() {
    let min = parseInt(this.poll.min, 10);
    if (isNaN(min) || min < 0) {
      min = 1;
    }

    return min;
  }

  get max() {
    let max = parseInt(this.poll.max, 10);
    const numOptions = this.poll.options.length;
    if (isNaN(max) || max > numOptions) {
      max = numOptions;
    }
    return max;
  }

  get closed() {
    return this.status === CLOSED_STATUS || this.isAutomaticallyClosed;
  }

  get rankedChoiceDropdownContent() {
    let rankedChoiceDropdownContent = [];

    rankedChoiceDropdownContent.push({
      id: 0,
      name: I18n.t("poll.options.ranked_choice.abstain"),
    });

    this.poll.options.forEach((option, i) => {
      option.rank = 0;
      rankedChoiceDropdownContent.push({
        id: i + 1,
        name: (i + 1).toString(),
      });
    });

    return rankedChoiceDropdownContent;
  }

  get isAutomaticallyClosed() {
    return (
      (this.poll.close ?? false) &&
      moment.utc(this.poll.close, "YYYY-MM-DD HH:mm:ss Z") <= moment()
    );
  }

  get hasVoted() {
    return this.vote?.length > 0;
  }

  get hideResultsDisabled() {
    return !this.staffOnly && (this.closed || this.topicArchived);
  }

  @action
  toggleOption(option, rank = 0) {
    if (this.closed) {
      return;
    }

    if (!this.currentUser) {
      // unlikely, handled by template logic
      return;
    }

    if (!this.checkUserGroups(this.currentUser, this.poll)) {
      return;
    }

    if (
      !this.isMultiple &&
      !this.isRankedChoice &&
      this.vote.length === 1 &&
      this.vote[0] === option.id
    ) {
      return this.removeVote();
    }

    if (!this.isMultiple && !this.isRankedChoice) {
      this.vote.length = 0;
    }

    this._toggleOption(option, rank);

    if (!this.isMultiple && !this.isRankedChoice) {
      this.castVotes(option);
    }
  }

  @action
  toggleResults() {
    this.showResults = !this.showResults;
  }

  get canCastVotes() {
    if (this.closed || !this.currentUser) {
      return false;
    }

    const selectedOptionCount = this.vote?.length || 0;

    if (this.isMultiple) {
      return selectedOptionCount >= this.min && selectedOptionCount <= this.max;
    }

    if (this.isRankedChoice) {
      return (
        this.options.length === this.vote?.length &&
        this.areRanksValid(this.vote)
      );
    }

    return selectedOptionCount > 0;
  }

  get notInVotingGroup() {
    return !this.checkUserGroups(this.currentUser, this.poll);
  }

  get pollGroups() {
    return I18n.t("poll.results.groups.title", { groups: this.poll.groups });
  }

  get showCastVotesButton() {
    return (this.isMultiple || this.isRankedChoice) && !this.showResults;
  }

  get castVotesButtonClass() {
    return `btn cast-votes ${
      this.canCastVotes ? "btn-primary" : "btn-default"
    }`;
  }

  get castVotesButtonIcon() {
    return !this.castVotesDisabled ? "check" : "far-square";
  }

  get castVotesDisabled() {
    return !this.canCastVotes;
  }

  get showHideResultsButton() {
    return this.showResults && !this.hideResultsDisabled;
  }

  get showShowResultsButton() {
    return (
      !this.showResults &&
      !this.hideResultsDisabled &&
      !(this.poll.results === ON_VOTE && !this.hasSavedVote && !this.isMe) &&
      !(this.poll.results === ON_CLOSE && !this.closed) &&
      !(this.poll.results === STAFF_ONLY && !this.isStaff) &&
      this.voters > 0
    );
  }

  get showRemoveVoteButton() {
    return (
      !this.showResults &&
      !this.closed &&
      !this.hideResultsDisabled &&
      this.hasSavedVote
    );
  }

  get isCheckbox() {
    return this.isMultiple;
  }

  get resultsWidgetTypeClass() {
    const type = this.poll.type;
    return this.isNumber || this.poll.chart_type !== PIE_CHART_TYPE
      ? `discourse-poll-${type}-results`
      : "discourse-poll-pie-chart";
  }

  get resultsPie() {
    return this.poll.chart_type === PIE_CHART_TYPE;
  }

  get averageRating() {
    const totalScore = this.options.reduce((total, o) => {
      return total + parseInt(o.html, 10) * parseInt(o.votes, 10);
    }, 0);

    const average = this.voters === 0 ? 0 : round(totalScore / this.voters, -2);

    return htmlSafe(I18n.t("poll.average_rating", { average }));
  }

  get availableDisplayMode() {
    if (
      !this.showResults ||
      this.poll.chart_type === PIE_CHART_TYPE ||
      ![REGULAR_POLL_TYPE, MULTIPLE_POLL_TYPE].includes(this.poll.type)
    ) {
      return null;
    }
    return this.showTally ? "showPercentage" : "showTally";
  }

  @action
  updatedVoters() {
    if (!this.voterListExpanded) {
      this.preloadedVoters = this.defaultPreloadedVoters();
    }
  }

  @action
  fetchVoters(optionId) {
    let preloadedVoters = this.preloadedVoters;

    Object.keys(preloadedVoters).forEach((key) => {
      if (key === optionId) {
        preloadedVoters[key].loading = true;
      }
    });

    let voters = optionId ? preloadedVoters[optionId].voters : preloadedVoters;
    const votersCount = voters.length;

    return ajax("/polls/voters.json", {
      data: {
        post_id: this.post.id,
        poll_name: this.poll.name,
        option_id: optionId,
        page: Math.floor(votersCount / FETCH_VOTERS_COUNT) + 1,
        limit: FETCH_VOTERS_COUNT,
      },
    })
      .then((result) => {
        this.voterListExpanded = true;
        const newVoters = optionId ? result.voters[optionId] : result.voters;
        let votersSet = new Set([]);

        if (this.isRankedChoice) {
          votersSet = new Set(voters.map((voter) => voter.user.username));
          newVoters.forEach((voter) => {
            if (!votersSet.has(voter.user.username)) {
              votersSet.add(voter.user.username);
              voters.push(voter);
            }
          });
        } else {
          votersSet = new Set(voters.map((voter) => voter.username));
          newVoters.forEach((voter) => {
            if (!votersSet.has(voter.username)) {
              votersSet.add(voter.username);
              voters.push(voter);
            }
          });
          // remove users who changed their vote
          if (this.poll.type === REGULAR) {
            Object.keys(preloadedVoters).forEach((otherOptionId) => {
              if (optionId !== otherOptionId) {
                preloadedVoters[otherOptionId].voters = preloadedVoters[
                  otherOptionId
                ].voters.filter((voter) => !votersSet.has(voter.username));
              }
            });
          }
        }
      })
      .catch((error) => {
        if (error) {
          popupAjaxError(error);
        } else {
          this.dialog.alert(I18n.t("poll.error_while_fetching_voters"));
        }
      })
      .finally(() => {
        preloadedVoters[optionId].loading = false;
        this.preloadedVoters = Object.assign({}, preloadedVoters);
      });
  }

  @action
  dropDownClick(dropDownAction) {
    this[dropDownAction]();
  }

  @action
  removeVote() {
    return ajax("/polls/vote", {
      type: "DELETE",
      data: {
        post_id: this.post.id,
        poll_name: this.poll.name,
      },
    })
      .then(({ poll }) => {
        if (this.poll.type === RANKED_CHOICE) {
          poll.options.forEach((option) => {
            option.rank = 0;
          });
        }
        this.vote = Object.assign([]);
        this.hasSavedVote = false;
        this.appEvents.trigger("poll:voted", poll, this.post, this.vote);
        this.showResults = false;
      })
      .catch((error) => popupAjaxError(error));
  }

  @action
  toggleStatus() {
    if (this.isAutomaticallyClosed) {
      return;
    }

    this.dialog.yesNoConfirm({
      message: I18n.t(this.closed ? "poll.open.confirm" : "poll.close.confirm"),
      didConfirm: () => {
        const status = this.closed ? OPEN_STATUS : CLOSED_STATUS;
        ajax("/polls/toggle_status", {
          type: "PUT",
          data: {
            post_id: this.post.id,
            poll_name: this.poll.name,
            status,
          },
        })
          .then(() => {
            this.poll.set("status", status);

            if (
              this.poll.results === ON_CLOSE ||
              this.poll.results === "always"
            ) {
              this.showResults = this.status === CLOSED_STATUS;
            }

            // Votes are only included in serialized results for results=ON_CLOSE when
            // the poll is closed, so we must refresh the page to pick these up.
            if (
              this.poll.results === ON_CLOSE &&
              this.status === CLOSED_STATUS
            ) {
              this.router.refresh();
            }
          })
          .catch((error) => {
            if (error) {
              popupAjaxError(error);
            } else {
              this.dialog.alert(I18n.t("poll.error_while_toggling_status"));
            }
          });
      },
    });
  }

  @action
  showBreakdown() {
    this.modal.show(PollBreakdownModal, {
      model: this.args.attrs,
    });
  }

  @action
  exportResults() {
    const queryID =
      this.poll.type === RANKED_CHOICE
        ? this.siteSettings.poll_export_ranked_choice_data_explorer_query_id
        : this.siteSettings.poll_export_data_explorer_query_id;

    // This uses the Data Explorer plugin export as CSV route
    // There is detection to check if the plugin is enabled before showing the button
    ajax(`/admin/plugins/explorer/queries/${queryID}/run.csv`, {
      type: "POST",
      data: {
        // needed for data-explorer route compatibility
        params: JSON.stringify({
          poll_name: this.poll.name,
          post_id: this.post.id.toString(), // needed for data-explorer route compatibility
        }),
        explain: false,
        limit: 1000000,
        download: 1,
      },
    })
      .then((csvContent) => {
        const downloadLink = document.createElement("a");
        const blob = new Blob([csvContent], {
          type: "text/csv;charset=utf-8;",
        });
        downloadLink.href = URL.createObjectURL(blob);
        downloadLink.setAttribute(
          "download",
          `poll-export-${this.poll.name}-${this.post.id}.csv`
        );
        downloadLink.click();
        downloadLink.remove();
      })
      .catch((error) => {
        if (error) {
          popupAjaxError(error);
        } else {
          this.dialog.alert(I18n.t("poll.error_while_exporting_results"));
        }
      });
  }

  @action
  toggleDisplayMode() {
    this.showTally = !this.showTally;
  }

  <template>
    <div
      {{didUpdate this.updatedVoters @preloadedVoters}}
      class="poll-container"
    >
      {{this.titleHTML}}
      {{#if this.notInVotingGroup}}
        <div class="alert alert-danger">{{this.pollGroups}}</div>
      {{/if}}
      {{#if this.showResults}}
        <div class={{this.resultsWidgetTypeClass}}>
          {{#if this.isNumber}}
            <span>{{this.averageRating}}</span>
          {{else}}
            {{#if this.resultsPie}}
              <PollResultsPie @id={{this.id}} @options={{this.options}} />
            {{else}}
              <PollResultsTabs
                @options={{this.options}}
                @pollName={{this.poll.name}}
                @pollType={{this.poll.type}}
                @isRankedChoice={{this.isRankedChoice}}
                @isPublic={{this.poll.public}}
                @postId={{this.post.id}}
                @vote={{this.vote}}
                @voters={{this.preloadedVoters}}
                @votersCount={{this.poll.voters}}
                @fetchVoters={{this.fetchVoters}}
                @rankedChoiceOutcome={{this.rankedChoiceOutcome}}
                @showTally={{this.showTally}}
              />
            {{/if}}
          {{/if}}
        </div>
      {{else}}
        <PollOptions
          @isCheckbox={{this.isCheckbox}}
          @isRankedChoice={{this.isRankedChoice}}
          @rankedChoiceDropdownContent={{this.rankedChoiceDropdownContent}}
          @options={{this.options}}
          @votes={{this.vote}}
          @sendOptionSelect={{this.toggleOption}}
        />
      {{/if}}
    </div>
    <PollInfo
      @options={{this.options}}
      @min={{this.min}}
      @max={{this.max}}
      @isMultiple={{this.isMultiple}}
      @close={{this.close}}
      @closed={{this.closed}}
      @results={{this.poll.results}}
      @showResults={{this.showResults}}
      @postUserId={{this.poll.post.user_id}}
      @isPublic={{this.poll.public}}
      @hasVoted={{this.hasVoted}}
      @voters={{this.voters}}
    />
    <div class="poll-buttons">
      {{#if this.showCastVotesButton}}
        <button
          class={{this.castVotesButtonClass}}
          title="poll.cast-votes.title"
          disabled={{this.castVotesDisabled}}
          {{on "click" this.castVotes}}
        >
          {{icon this.castVotesButtonIcon}}
          <span class="d-button-label">{{i18n "poll.cast-votes.label"}}</span>
        </button>
      {{/if}}

      {{#if this.showHideResultsButton}}
        <button
          class="btn btn-default toggle-results"
          title="poll.hide-results.title"
          {{on "click" this.toggleResults}}
        >
          {{icon "chevron-left"}}
          <span class="d-button-label">{{i18n "poll.hide-results.label"}}</span>
        </button>
      {{/if}}

      {{#if this.showShowResultsButton}}
        <button
          class="btn btn-default toggle-results"
          title="poll.show-results.title"
          {{on "click" this.toggleResults}}
        >
          {{icon "chart-bar"}}
          <span class="d-button-label">{{i18n "poll.show-results.label"}}</span>
        </button>
      {{/if}}

      {{#if this.showRemoveVoteButton}}
        <button
          class="btn btn-default remove-vote"
          title="poll.remove-vote.title"
          {{on "click" this.removeVote}}
        >
          {{icon "undo"}}
          <span class="d-button-label">{{i18n "poll.remove-vote.label"}}</span>
        </button>
      {{/if}}

      <PollButtonsDropdown
        @closed={{this.closed}}
        @voters={{this.voters}}
        @isStaff={{this.isStaff}}
        @isMe={{this.isMe}}
        @isRankedChoice={{this.isRankedChoice}}
        @topicArchived={{this.topicArchived}}
        @groupableUserFields={{this.groupableUserFields}}
        @isAutomaticallyClosed={{this.isAutomaticallyClosed}}
        @dropDownClick={{this.dropDownClick}}
        @availableDisplayMode={{this.availableDisplayMode}}
      />
    </div>
  </template>
}
