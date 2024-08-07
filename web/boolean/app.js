const FILL_STYLES = {
  none: "bg-white",
  and: "bg-red-500",
  or: "bg-yellow-400",
  not: "bg-green-500",
};

const HINT_TEXT = {
  none: "Select a boolean operator to see how it works.",
  and: "When using AND, you only receive pages including both of your search terms, though not necessarily next to one another.",

  or: "When using OR, you receive pages containing either one or both of your search terms.",
  not: "The NOT operator is used to find pages including only the first term and excluding the second term.",
};

Vue.component("boolean-machine", {
  template: `
  <div class="container mx-auto">
    <div class="my-4 md:mb-8">
      <h1 class="text-center text-xl md:text-3xl">
        The Boolean Machine
        <span
          class="align-text-top text-xs md:text-base font-semibold text-slate-500 -ml-1"
        >3</span>
      </h1>
      <h2 class="text-center text-sm md:text-base font-medium text-slate-500">
        Since 2000 –
        by
        <a
          href="https://rockwellschrock.com/"
          class="underline hover:text-slate-700"
        >Rockwell Schrock</a>
      </h2>
    </div>

    <div class="relative md:flex">
      <div
        class="flex md:flex-col px-4 md:px-0 lg:pr-32 md:pr-16 space-x-2 md:space-x-0 text-xl lg:text-3xl"
      >
        <button
          :class="[buttonClasses.and, 'flex-1 focus:outline-none rounded-lg border-4 border-transparent hover:border-slate-600 cursor-pointer text-center py-2 lg:py-6 mb-8 md:mb-4 md:px-12 transition-border duration-300']"
          @click="setOperator('and')"
        >AND</button>

        <button
          :class="[buttonClasses.or, 'flex-1 focus:outline-none rounded-lg border-4 border-transparent hover:border-slate-600 cursor-pointer text-center py-2 lg:py-6 mb-8 md:mb-4 md:px-12 transition-border duration-300']"
          @click="setOperator('or')"
        >OR</button>

        <button
          :class="[buttonClasses.not, 'flex-1 focus:outline-none rounded-lg border-4 border-transparent hover:border-slate-600 cursor-pointer text-center py-2 lg:py-6 mb-8 md:mb-4 md:px-12 transition-border duration-300']"
          @click="setOperator('not')"
        >NOT</button>
      </div>

      <div
        class="flex-grow relative mx-4 md:mx-0"
        @mouseleave="highlightInputs = false"
        @mouseenter="highlightInputs = true"
      >
        <!-- White-filled BG circles establish the height of this flex block, for positioning -->
        <div class="flex">
          <div class="relative" style="width: 60%; padding-bottom: 60%">
            <div class="absolute inset-0 bg-white rounded-full" />
          </div>
          <div class="relative" style="width: 60%; padding-bottom: 60%; margin-left: -20%">
            <div class="absolute inset-0 bg-white rounded-full" />
          </div>
        </div>

        <!-- Color-filled circles to show operation -->
        <div class="flex absolute inset-0">
          <div class="relative" style="width: 60%; padding-bottom: 60%">
            <div :class="['absolute inset-0 border-4 rounded-full', leftFillClass]" />
          </div>
          <div class="relative" style="width: 60%; padding-bottom: 60%; margin-left: -20%">
            <div
              :class="['absolute inset-0 border-4 rounded-full', rightFillClass]"
              :style="clipStyle"
            />
          </div>
        </div>

        <!-- Black borders -->
        <div class="flex absolute inset-0">
          <div class="relative" style="width: 60%; padding-bottom: 60%">
            <div class="absolute inset-0 border-4 border-black rounded-full" />
          </div>
          <div class="relative" style="width: 60%; padding-bottom: 60%; margin-left: -20%">
            <div class="absolute inset-0 border-4 border-black rounded-full" />
          </div>
        </div>

        <div
          class="flex absolute inset-0 text-xl sm:text-3xl md:text-xl lg:text-3xl items-center justify-between"
        >
          <div style="width: 40%" class="px-4 md:px-8">
            <input
              type="text"
              :class="[inputOpacityClass, 'w-full bg-slate-800 transition-border duration-300 text-center outline-none placeholder-slate-800 border-b-2 border-black border-opacity-0 hover:border-opacity-25 focus:border-opacity-25']"
              placeholder="Endangered"
              v-model="query1"
            />
          </div>
          <div>{{ operatorText }}</div>
          <div style="width: 40%" class="px-4 md:px-8">
            <input
              type="text"
              :class="[inputOpacityClass, 'w-full bg-slate-800 transition-border duration-300 text-center outline-none placeholder-slate-800 border-b-2 border-black border-opacity-0 hover:border-opacity-25 focus:border-opacity-25']"
              placeholder="Birds"
              v-model="query2"
            />
          </div>
        </div>
      </div>
    </div>
    <div class="px-4 my-8 md:my-12 text-lg md:text-3xl text-center">{{ hintText }}</div>

    <div class="border-t border-slate-400 my-8 py-8 mx-4 md:mx-0">
      <p class="block md:hidden mb-4 text-slate-600">
        <span class="font-semibold bg-teal-500 text-white px-2 py-1 mr-2 text-sm rounded-full">NEW!</span>Type your own search terms into the diagram.
      </p>

      <div class="flex justify-between">
        <button class="text-slate-600 flex items-center" @click="showInfo = !showInfo">
          <div
            class="w-6 mr-2 text-bold text-lg bg-slate-300 rounded leading-6"
          >{{ showInfo ? '–' : '+'}}</div>More Info
        </button>

        <p class="hidden md:block text-slate-600">
          <span
            class="font-semibold bg-teal-500 text-white px-2 py-1 mr-2 text-sm rounded-full"
          >NEW!</span>Type your own search terms into the diagram.
        </p>
      </div>

      <div v-show="showInfo" class="my-4">
        <p class="mb-4">
          By
          <a
            href="https://rockwellschrock.com"
            class="underline hover:text-slate-600"
          >Rockwell Schrock</a> &ndash;
          <a
            href="mailto:schrockwell@gmail.com"
            class="underline hover:text-slate-600"
          >schrockwell@gmail.com</a>
        </p>
        <p
          class="my-4"
        >You are free to use this page in your presentations, course materials, or anything else.</p>

        <h4 class="text-lg font-semibold mt-8">Custom URL</h4>
        <p
          class="text-slate-600 mb-1"
        >Copy this URL to save the own custom search terms that you've typed in.</p>
        <input
          type="text"
          class="w-full border rounded bg-white shadow-inner px-3 py-2 font-mono text-sm"
          readonly
          :value="customUrl"
        />

        <h4 class="text-lg font-semibold mt-8">Embed Code</h4>
        <p
          class="text-slate-600 mb-1"
        >Use this HTML to embed the Boolean Machine directly into another page.</p>
        <textarea
          readonly
          rows="3"
          class="w-full border rounded bg-white shadow-inner px-3 py-2 font-mono text-sm"
          v-model="embedCode"
        />
      </div>
    </div>
  </div>
    `,

  mounted() {
    // Only run this client-side, since we need window.location, etc
    if (window) {
      this.updateURL();
    }
  },

  data() {
    const params = new URL(document.location.toString()).searchParams;
    return {
      showInfo: false,
      operator: "none",
      //   query1: this.$route.query.query1 || "",
      //   query2: this.$route.query.query2 || "",
      // get from query params
      query1: params.get("query1") || "",
      query2: params.get("query2") || "",
      customUrl: "",
      highlightInputs: false,
    };
  },

  methods: {
    updateURL() {
      if (this.query1 || this.query2) {
        const queryParams = `?query1=${window.encodeURIComponent(
          this.query1
        )}&query2=${window.encodeURIComponent(this.query2)}`;
        window.history.replaceState(null, "", queryParams);
      } else {
        window.history.replaceState(null, "", "/boolean");
      }

      this.customUrl = window.location.href;
    },

    setOperator(operator) {
      if (this.operator === operator) {
        this.operator = "none";
      } else {
        this.operator = operator;
      }
    },
  },

  computed: {
    inputOpacityClass() {
      return this.highlightInputs ? "bg-opacity-10" : "bg-opacity-0";
    },

    hintText() {
      return HINT_TEXT[this.operator];
    },

    operatorText() {
      if (this.operator === "none") {
        return null;
      } else {
        return this.operator.toUpperCase();
      }
    },

    fillStyles() {
      return FILL_STYLES;
    },

    fillClass() {
      return FILL_STYLES[this.operator];
    },

    buttonClasses() {
      return {
        and: this.operator === "and" ? FILL_STYLES.and : "bg-slate-300",
        or: this.operator === "or" ? FILL_STYLES.or : "bg-slate-300",
        not: this.operator === "not" ? FILL_STYLES.not : "bg-slate-300",
      };
    },

    leftFillClass() {
      switch (this.operator) {
        case "or":
          return FILL_STYLES.or;
        case "not":
          return FILL_STYLES.not;
        case "and":
        default:
          return undefined;
      }
    },

    rightFillClass() {
      switch (this.operator) {
        case "and":
          return FILL_STYLES.and;
        case "or":
          return FILL_STYLES.or;
        case "not":
          return FILL_STYLES.none;
        default:
          return undefined;
      }
    },

    clipStyle() {
      if (this.operator === "and") {
        return "clip-path: circle(50% at -16.6667% 50%)";
      } else {
        return null;
      }
    },

    embedCode() {
      return `<iframe src="${this.customUrl}" width="100%" height="500"> 
<p>Your browser does not support iframes</p>
</iframe>`;
    },
  },

  watch: {
    query1() {
      this.updateURL();
    },
    query2() {
      this.updateURL();
    },
  },
});

const app = new Vue({
  el: "#app",
});
