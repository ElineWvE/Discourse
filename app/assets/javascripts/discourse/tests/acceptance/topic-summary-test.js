import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import topicFixtures from "discourse/tests/fixtures/topic";
import {
  acceptance,
  publishToMessageBus,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";
import { cloneJSON } from "discourse-common/lib/object";

acceptance("Topic - Summary", function (needs) {
  const currentUserId = 5;

  needs.user();
  needs.pretender((server, helper) => {
    server.get("/t/1.json", () => {
      const json = cloneJSON(topicFixtures["/t/130.json"]);
      json.id = 1;
      json.summarizable = true;

      return helper.response(json);
    });

    server.get("/t/1/strategy-summary", () => {
      return helper.response({});
    });
  });

  needs.hooks.beforeEach(() => {
    updateCurrentUser({ id: currentUserId });
  });

  test("displays streamed summary", async function (assert) {
    await visit("/t/-/1");

    const partialSummary = "This a";
    await publishToMessageBus("/summaries/topic/1", {
      done: false,
      topic_summary: { summarized_text: partialSummary },
    });

    await click(".topic-strategy-summarization");

    assert
      .dom(".summary-box .generated-summary p")
      .hasText(partialSummary, "Updates the summary with a partial result");

    const finalSummary = "This is a completed summary";
    await publishToMessageBus("/summaries/topic/1", {
      done: true,
      topic_summary: {
        summarized_text: finalSummary,
        summarized_on: "2023-01-01T04:00:00.000Z",
        algorithm: "OpenAI GPT-4",
        outdated: false,
        new_posts_since_summary: false,
        can_regenerate: true,
      },
    });

    assert
      .dom(".summary-box .generated-summary p")
      .hasText(finalSummary, "Updates the summary with a final result");

    assert.dom(".summary-box .summarized-on").exists("summary metadata exists");
  });
});

acceptance("Topic - Summary - Anon", function (needs) {
  const finalSummary = "This is a completed summary";

  needs.pretender((server, helper) => {
    server.get("/t/1.json", () => {
      const json = cloneJSON(topicFixtures["/t/280/1.json"]);
      json.id = 1;
      json.summarizable = true;

      return helper.response(json);
    });

    server.get("/t/1/strategy-summary", () => {
      return helper.response({
        topic_summary: {
          summarized_text: finalSummary,
          summarized_on: "2023-01-01T04:00:00.000Z",
          algorithm: "OpenAI GPT-4",
          outdated: false,
          new_posts_since_summary: false,
          can_regenerate: false,
        },
      });
    });
  });

  test("displays cached summary inmediately", async function (assert) {
    await visit("/t/-/1");

    await click(".topic-strategy-summarization");

    assert
      .dom(".summary-box .generated-summary p")
      .hasText(finalSummary, "Updates the summary with the result");

    assert.dom(".summary-box .summarized-on").exists("summary metadata exists");
  });
});
