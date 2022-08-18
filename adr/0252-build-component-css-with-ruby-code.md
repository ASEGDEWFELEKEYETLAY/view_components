# 252. Build component css with ruby code

Date: 2022-08-17

## Status

Proposed

## Context

### What

We've talked a few times about the overhead it takes to develop components twice for rails architecture. Once in [primer/css](https://github.com/primer/css/pull/2083) and again in [primer/view_components](https://github.com/primer/view_components/pull/1225). This disconnect can lead to multiple versions and iterations happening in primer/css before any component is actually ready. [^1] [^2] [^3] [^4] [^5] [^6]

This pull aims to mirror what we did for delivering web-components with PVC but for CSS. We worked on this in another PR to see if we could render a `SegmentedControl` https://github.com/primer/view_components/pull/1315 to add a postcss pipeline and compile the `segmented_control.css`. Ideally I would like to leave the bundle in this PR empty, and add the component css in my `segmented_control` branch.

### How

Because this is essentially a new build system, we want to be more forward thinking with the code written here and opt for using [PostCSS] with the [preset-env] plugin that allows us to write more CSS spec features like, nested selectors, match functions, container queries etc. 

1. 👀 We made a PR for testing with a [docs build] that has `SegmentedControl` rendered from the PVC package. What you're seeing on that page is the component rendered with the CSS provided by the bundle.
2. 👀 We also test published a [`pre` version] from this pull request that contains an **empty for now** css bundle file compiled from the `primer.css` source.

Currently this runs on the `build:css` package.json script. Running a postcss-cli command. I intentionally left this pretty simple because I figured we might want to integrate this into rollup or webpack later.

In our github.com production bundle we have a few options:

1. We could include the compiled css file in our main bundle by adding a `@import "@primer/view-components/app/assets/styles/primer_view_components.css"` import line. This is most likely what we'll start with.
2. We could use css modules to load specific bundles for each component dynamically when the component is included on the page. This is more work, but would be worth the reward.

[docs build]: https://primer-904b32aa7f-26611710.drafts.github.io/components/alpha/segmentedcontrol
[`pre` version]: https://unpkg.com/browse/@primer/view-components@0.0.0-pre.7f94707/app/assets/styles/primer_view_components.css
[PostCSS]: https://postcss.org/
[preset-env]: https://preset-env.cssdb.org/
[^1]: https://github.com/primer/css/pull/2083
[^2]: https://github.com/primer/css/pull/2174
[^3]: https://github.com/primer/css/pull/2194
[^4]: https://github.com/primer/css/pull/2195
[^5]: https://github.com/primer/css/pull/2202
[^6]: https://github.com/primer/css/pull/2205

## Decision

<!-- The change that we're proposing or have agreed to implement. -->

Any new View Components should include corresponding CSS in this repository.

## Considered Options

- Keep component CSS separate in primer/css
  - Pros:
    - Doesn't require us to change already established norms.
    - Has storybook site
  - Cons:
    - Requires extra releases in both libraries when iterating on component architecture.
    - Cognitive disassociation between Primer::ViewComponent and .PrimerCssComponent
    - Stuck using old SCSS technology

## Consequences

<!-- What becomes easier or more difficult to do and any risks introduced by the change that will need to be mitigated.-->

- 
- 
