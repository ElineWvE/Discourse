import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";

export default class UserInvitedIndex extends DiscourseRoute {
  @service router;

  beforeModel() {
    this.router.replaceWith("userInvited.show", "pending");
  }
}
