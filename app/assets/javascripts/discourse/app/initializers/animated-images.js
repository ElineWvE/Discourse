import { iconHTML } from "discourse-common/lib/icon-library";
import { prefersReducedMotion } from "discourse/lib/utilities";
import { withPluginApi } from "discourse/lib/plugin-api";

let _gifClickHandlers = {};

export default {
  name: "animated-images-pause-on-click",

  initialize() {
    withPluginApi("0.8.7", (api) => {
      function _cleanUp() {
        Object.values(_gifClickHandlers || {}).forEach((handler) => {
          handler.removeEventListener("click", _handleEvent);
          handler.removeEventListener("load", _handleEvent);
        });

        _gifClickHandlers = {};
      }

      function _handleEvent(event) {
        const img = event.target;
        if (img && !img.previousSibling) {
          _pauseAnimation(img, { manualPause: true });
        } else {
          _resumeAnimation(img);
        }
      }

      function _pauseAnimation(img, opts = {}) {
        let canvas = document.createElement("canvas");
        canvas.width = img.width;
        canvas.height = img.height;
        canvas.getContext("2d").drawImage(img, 0, 0, img.width, img.height);
        canvas.setAttribute("aria-hidden", "true");
        canvas.setAttribute("role", "presentation");

        if (opts.manualPause) {
          img.classList.add("manually-paused");
        }
        img.parentNode.classList.add("paused-animated-image");
        img.parentNode.insertBefore(canvas, img);
      }

      function _resumeAnimation(img) {
        img.previousSibling.remove();
        img.parentNode.classList.remove("paused-animated-image");
        img.parentNode.classList.remove("manually-paused");
      }

      function _attachCommands(post, helper) {
        if (!helper) {
          return;
        }

        let images = post.querySelectorAll("img.animated");

        images.forEach((img) => {
          // skip for edge case of multiple animated images in same block
          if (img.parentNode.querySelectorAll("img").length > 1) {
            return;
          }

          if (_gifClickHandlers[img.src]) {
            _gifClickHandlers[img.src].removeEventListener(
              "click",
              _handleEvent
            );
            _gifClickHandlers[img.src].removeEventListener(
              "load",
              _handleEvent
            );
            delete _gifClickHandlers[img.src];
          }

          _gifClickHandlers[img.src] = img;
          img.addEventListener("click", _handleEvent, false);

          if (prefersReducedMotion()) {
            img.addEventListener("load", _handleEvent, false);
          }

          img.parentNode.classList.add("pausable-animated-image");
          const overlay = document.createElement("div");
          overlay.classList.add("animated-image-overlay");
          overlay.setAttribute("aria-hidden", "true");
          overlay.setAttribute("role", "presentation");
          overlay.innerHTML = `${iconHTML("pause")}${iconHTML("play")}`;
          img.parentNode.appendChild(overlay);
        });
      }

      api.decorateCookedElement(_attachCommands, {
        onlyStream: true,
        id: "animated-images-pause-on-click",
      });

      api.cleanupStream(_cleanUp);

      // paused on load when prefers-reduced-motion is active, no need for blur/focus events
      if (!prefersReducedMotion()) {
        const images = "img.animated:not(.manually-paused)";

        window.addEventListener("blur", () => {
          document.querySelectorAll(images).forEach((img) => {
            if (
              img.parentNode.querySelectorAll("img").length === 1 &&
              !img.previousSibling
            ) {
              _pauseAnimation(img);
            }
          });
        });

        window.addEventListener("focus", () => {
          document.querySelectorAll(images).forEach((img) => {
            if (
              img.parentNode.querySelectorAll("img").length === 1 &&
              img.previousSibling
            ) {
              _resumeAnimation(img);
            }
          });
        });
      }
    });
  },
};
