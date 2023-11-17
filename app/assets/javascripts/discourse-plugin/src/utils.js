import { factory } from "ember-polaris-service";

export function lookupService(name) {
  return factory((owner) => owner.lookup(`service:${name}`));
}
