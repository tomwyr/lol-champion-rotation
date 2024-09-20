function initData() {
  return {
    state: "loading",
    rotation: {},

    async fetchRotation() {
      this.state = "loading";

      const data = await fetch("/api/rotation/current");

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
