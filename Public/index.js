function initData() {
  return {
    sessionKey: "",
    state: "loading",
    rotation: {},

    async fetchRotation() {
      this.state = "loading";

      if (!this.sessionKey) {
        this.sessionKey = await generateSessionKey();
      }
      const data = await fetch("/api/rotation/current", {
        headers: { "X-Session-Key": this.sessionKey },
      });

      if (data.ok) {
        this.state = "data";
        this.rotation = await data.json();
      } else {
        this.state = "error";
        this.rotation = {};
      }
    },
  };
}

async function generateSessionKey() {
  await uuidLoaded();
  return window.uuid.v4();
}

function uuidLoaded() {
  return new Promise((resolve) => {
    if (window.uuid) {
      resolve();
    } else {
      document.querySelector("#uuid-js").addEventListener("load", resolve);
    }
  });
}
