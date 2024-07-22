import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { gt } from "truth-helpers";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import DButton from "discourse/components/d-button";
import TopicMapLink from "discourse/components/topic-map/topic-map-link";
import TopicParticipants from "discourse/components/topic-map/topic-participants";
import TopicViews from "discourse/components/topic-map/topic-views";
import TopicViewsChart from "discourse/components/topic-map/topic-views-chart";
import avatar from "discourse/helpers/bound-avatar-template";
import number from "discourse/helpers/number";
import { ajax } from "discourse/lib/ajax";
import { emojiUnescape } from "discourse/lib/text";
import dIcon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import I18n from "discourse-i18n";
import DMenu from "float-kit/components/d-menu";

const TRUNCATED_LINKS_LIMIT = 5;
const MIN_POST_READ_TIME = 4;
const MIN_LIKES_COUNT = 5;
const MIN_PARTICIPANTS_COUNT = 5;
const MIN_USERS_COUNT_FOR_AVATARS = 2;

export const MIN_POSTS_COUNT = 10;

export default class TopicMapSummary extends Component {
  @service site;
  @service siteSettings;
  @service mapCache;
  @service dialog;

  @tracked allLinksShown = false;
  @tracked top3LikedPosts = [];
  @tracked views = [];
  @tracked loading = true;

  get shouldShowParticipants() {
    return (
      this.args.topic.posts_count >= MIN_POSTS_COUNT &&
      this.args.topicDetails.participants?.length >=
        MIN_USERS_COUNT_FOR_AVATARS &&
      !this.site.mobileView
    );
  }

  get first5Participants() {
    return this.args.topicDetails.participants;
  }

  get readTimeMinutes() {
    const calculatedTime = Math.ceil(
      Math.max(
        this.args.topic.word_count / this.siteSettings.read_time_word_count,
        (this.args.topic.posts_count * MIN_POST_READ_TIME) / 60
      )
    );

    return calculatedTime > 3 ? calculatedTime : null;
  }

  get topRepliesSummaryEnabled() {
    return this.args.postStream.summary;
  }

  get topRepliesTitle() {
    if (this.topRepliesSummaryEnabled) {
      return;
    }

    return I18n.t("summary.short_title");
  }

  get topRepliesIcon() {
    return this.topRepliesSummaryEnabled ? "arrows-alt-v" : "layer-group";
  }

  get topRepliesLabel() {
    return this.topRepliesSummaryEnabled
      ? I18n.t("summary.show_all_label")
      : I18n.t("summary.short_label");
  }

  get loneStat() {
    if (this.args.topic.has_summary) {
      return false;
    }

    return (
      [this.hasViews, this.hasLikes, this.hasUsers, this.hasLinks].filter(
        Boolean
      ).length === 1
    );
  }

  get linksCount() {
    return this.args.topicDetails.links?.length ?? 0;
  }

  get topicLinks() {
    return this.args.topicDetails.links;
  }

  get linksToShow() {
    return this.allLinksShown
      ? this.topicLinks
      : this.topicLinks?.slice(0, TRUNCATED_LINKS_LIMIT);
  }

  get hasMoreLinks() {
    return !this.allLinksShown && this.linksCount > TRUNCATED_LINKS_LIMIT;
  }

  get hasViews() {
    return this.args.topic.views > 1;
  }

  get hasLikes() {
    return (
      this.args.topic.like_count > MIN_LIKES_COUNT &&
      this.args.topic.posts_count > MIN_POSTS_COUNT
    );
  }

  get hasUsers() {
    return this.args.topic.participant_count > MIN_PARTICIPANTS_COUNT;
  }

  get hasLinks() {
    return this.linksCount > 0;
  }

  @action
  showAllLinks() {
    this.allLinksShown = true;
  }

  @action
  showTopReplies() {
    this.args.postStream.showTopReplies();
  }

  @action
  cancelFilter() {
    this.args.postStream.cancelFilter();
    this.args.postStream.refresh();
  }

  @action
  postUrl(post) {
    return this.args.topic.urlForPostNumber(post.post_number);
  }

  @action
  fetchMostLiked() {
    const cacheKey = `top3LikedPosts_${this.args.topic.id}`;
    const cachedData = this.mapCache.get(cacheKey);
    this.loading = true;

    if (cachedData) {
      this.top3LikedPosts = cachedData;
      this.loading = false;
      return;
    }

    const filter = `/search.json?q=" " topic%3A${this.args.topic.id} order%3Alikes`;

    ajax(filter)
      .then((data) => {
        const top3LikedPosts = data.posts
          .filter((post) => post.post_number > 1 && post.like_count > 0)
          .sort((a, b) => b.like_count - a.like_count)
          .slice(0, 3);

        this.mapCache.set(cacheKey, top3LikedPosts);
        this.top3LikedPosts = top3LikedPosts;
      })
      .catch((error) => {
        this.dialog.alert(
          I18n.t("generic_error_with_reason", {
            error: `http: ${error.status} - ${error.body}`,
          })
        );
      })
      .finally(() => {
        this.loading = false;
      });
  }

  @action
  fetchViews() {
    const cacheKey = `topicViews_${this.args.topic.id}`;
    const cachedData = this.mapCache.get(cacheKey);
    this.loading = true;

    if (cachedData) {
      this.views = cachedData;
      this.loading = false;
      return;
    }

    ajax(`/t/${this.args.topic.id}/view-stats.json`)
      .then((data) => {
        if (data.stats.length) {
          this.views = data;
        } else {
          data.stats.push({
            viewed_at: new Date().toISOString().split("T")[0],
            views: this.args.topic.views,
          });
          this.views = data;
        }
        this.mapCache.set(cacheKey, data);
      })
      .catch((error) => {
        this.dialog.alert(
          I18n.t("generic_error_with_reason", {
            error: `http: ${error.status} - ${error.body}`,
          })
        );
      })
      .finally(() => {
        this.loading = false;
      });
  }

  <template>
    <div class="topic-map__stats {{if this.loneStat '--single-stat'}}">
      <DMenu
        @arrow={{true}}
        @identifier="topic-map__views"
        @interactive={{true}}
        @triggers="click"
        @modalForMobile={{true}}
        @placement="right"
        @groupIdentifier="topic-map"
        @inline={{true}}
        @onShow={{this.fetchViews}}
      >
        <:trigger>
          {{number @topic.views noTitle="true"}}
          <span class="topic-map__stat-label">
            {{i18n "views_lowercase" count=@topic.views}}
          </span>
        </:trigger>
        <:content>
          <h3>{{i18n "topic_map.menu_titles.views"}}</h3>
          <ConditionalLoadingSpinner @condition={{this.loading}}>
            {{#if (gt this.views.stats.length 2)}}
              <TopicViewsChart
                @views={{this.views}}
                @created={{@topic.created_at}}
              />
            {{else}}
              <TopicViews @views={{this.views}} />
            {{/if}}
          </ConditionalLoadingSpinner>
        </:content>
      </DMenu>

      {{#if this.hasLikes}}
        <DMenu
          @arrow={{true}}
          @identifier="topic-map__likes"
          @interactive={{true}}
          @triggers="click"
          @modalForMobile={{true}}
          @placement="right"
          @groupIdentifier="topic-map"
          @inline={{true}}
        >
          <:trigger>
            {{number @topic.like_count noTitle="true"}}
            <span class="topic-map__stat-label">
              {{i18n "likes_lowercase" count=@topic.like_count}}
            </span>
          </:trigger>
          <:content>
            <h3 {{didInsert this.fetchMostLiked}}>{{i18n
                "topic_map.menu_titles.replies"
              }}</h3>
            <ConditionalLoadingSpinner @condition={{this.loading}}>
              <ul>
                {{#each this.top3LikedPosts as |post|}}
                  <li>
                    <a href={{this.postUrl post}}>
                      <span class="like-section__user">
                        {{avatar
                          post.avatar_template
                          "tiny"
                          (hash title=post.username)
                        }}
                        {{post.username}}
                      </span>
                      <span class="like-section__likes">
                        {{post.like_count}}
                        {{dIcon "heart"}}</span>
                      <p>
                        {{htmlSafe (emojiUnescape post.blurb)}}
                      </p>
                    </a>
                  </li>
                {{/each}}
              </ul>
            </ConditionalLoadingSpinner>
          </:content>
        </DMenu>
      {{/if}}

      {{#if this.linksCount}}
        <DMenu
          @arrow={{true}}
          @identifier="topic-map__links"
          @interactive={{true}}
          @triggers="click"
          @modalForMobile={{true}}
          @groupIdentifier="topic-map"
          @placement="right"
          @inline={{true}}
        >
          <:trigger>
            {{number this.linksCount noTitle="true"}}
            <span class="topic-map__stat-label">
              {{i18n "links_lowercase" count=this.linksCount}}
            </span>
          </:trigger>
          <:content>
            <h3>{{i18n "topic_map.links_title"}}</h3>
            <table class="topic-links">
              <tbody>
                {{#each this.linksToShow as |link|}}
                  <tr>
                    <td>
                      <span
                        class="badge badge-notification clicks"
                        title={{i18n "topic_map.clicks" count=link.clicks}}
                      >
                        {{link.clicks}}
                      </span>
                    </td>
                    <td>
                      <TopicMapLink
                        @attachment={{link.attachment}}
                        @title={{link.title}}
                        @rootDomain={{link.root_domain}}
                        @url={{link.url}}
                        @userId={{link.user_id}}
                      />
                    </td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
            {{#if this.hasMoreLinks}}
              <div class="link-summary">
                <span>
                  <DButton
                    @action={{this.showAllLinks}}
                    @title="topic_map.links_shown"
                    @icon="chevron-down"
                    class="btn-flat"
                  />
                </span>
              </div>
            {{/if}}
          </:content>
        </DMenu>
      {{/if}}

      {{#if this.hasUsers}}
        <DMenu
          @arrow={{true}}
          @identifier="topic-map__users"
          @interactive={{true}}
          @triggers="click"
          @placement="right"
          @modalForMobile={{true}}
          @groupIdentifier="topic-map"
          @inline={{true}}
        >
          <:trigger>
            {{number @topic.participant_count noTitle="true"}}
            <span class="topic-map__stat-label">
              {{i18n "users_lowercase" count=@topic.participant_count}}
            </span>
          </:trigger>
          <:content>
            <TopicParticipants
              @title={{i18n "topic_map.participants_title"}}
              @userFilters={{@userFilters}}
              @participants={{@topicDetails.participants}}
            />
          </:content>
        </DMenu>
      {{/if}}

      {{#if this.shouldShowParticipants}}
        <TopicParticipants
          @participants={{this.first5Participants}}
          @userFilters={{@userFilters}}
        />
      {{/if}}
      <div class="topic-map__buttons">
        {{#if this.readTimeMinutes}}
          <div class="estimated-read-time">
            <span> {{i18n "topic_map.read"}} </span>
            <span>
              {{this.readTimeMinutes}}
              {{i18n "topic_map.minutes"}}
            </span>
          </div>
        {{/if}}
        <div class="summarization-buttons">
          {{#if @topic.has_summary}}
            <DButton
              @action={{if
                @postStream.summary
                this.cancelFilter
                this.showTopReplies
              }}
              @translatedTitle={{this.topRepliesTitle}}
              @translatedLabel={{this.topRepliesLabel}}
              @icon={{this.topRepliesIcon}}
              class="top-replies"
            />
          {{/if}}
        </div>
      </div>
    </div>
  </template>
}
