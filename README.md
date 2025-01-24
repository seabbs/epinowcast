
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Flexible Hierarchical Nowcasting <a href="https://package.epinowcast.org/"><img src="man/figures/logo.png" align="right" height="139" alt="epinowcast website" /></a>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R-CMD-check](https://github.com/epinowcast/epinowcast/workflows/R-CMD-check/badge.svg)](https://github.com/epinowcast/epinowcast/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/epinowcast/epinowcast/branch/main/graph/badge.svg)](https://app.codecov.io/gh/epinowcast/epinowcast)
</br>
[![Universe](https://epinowcast.r-universe.dev/badges/epinowcast)](https://epinowcast.r-universe.dev/epinowcast)
[![MIT
license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/epinowcast/epinowcast/blob/master/LICENSE.md/)
[![GitHub
contributors](https://img.shields.io/github/contributors/epinowcast/epinowcast)](https://github.com/epinowcast/epinowcast/graphs/contributors)
</br>
[![DOI](https://zenodo.org/badge/422611952.svg)](https://zenodo.org/badge/latestdoi/422611952)
<!-- badges: end -->

## Summary

Tools to enable flexible and efficient hierarchical nowcasting of
right-truncated epidemiological time-series using a semi-mechanistic
Bayesian model with support for a range of reporting and generative
processes. Nowcasting, in this context, is gaining situational awareness
using currently available observations and the reporting patterns of
historical observations. This can be useful when tracking the spread of
infectious disease in real-time: without nowcasting, changes in trends
can be obfuscated by partial reporting or their detection may be delayed
due to the use of simpler methods like truncation. While the package has
been designed with epidemiological applications in mind, it could be
applied to any set of right-truncated time-series count data.

## Installation

<details>
<summary>
Installing the package
</summary>

You can install the latest released version using the normal `R`
function, though you need to point to `r-universe` instead of CRAN:

``` r
install.packages(
  "epinowcast", repos = "https://epinowcast.r-universe.dev"
)
```

Alternatively, you can use the [`remotes`
package](https://remotes.r-lib.org/) to install the development version
from Github (warning! this version may contain breaking changes and/or
bugs):

``` r
remotes::install_github(
  "epinowcast/epinowcast", dependencies = TRUE
)
```

Similarly, you can install historical versions by specifying the release
tag (e.g. this installs
[`0.2.0`](https://github.com/epinowcast/epinowcast/releases/tag/v0.2.0)):

``` r
remotes::install_github(
  "epinowcast/epinowcast", dependencies = TRUE, ref = "v0.2.0"
)
```

*Note: You can also use that last approach to install a specific commit
if needed, e.g. if you want to try out a specific unreleased feature,
but not the absolute latest developmental version.*

</details>
<details>
<summary>
Installing CmdStan
</summary>

If you wish to do model fitting and nowcasting, you will need to install
[CmdStan](https://mc-stan.org/users/interfaces/cmdstan), which also
entails having a suitable C++ toolchain setup. We recommend using the
[`cmdstanr` package](https://mc-stan.org/cmdstanr/). The Stan team
provides instructions in the [*Getting started with
`cmdstanr`*](https://mc-stan.org/cmdstanr/articles/cmdstanr.html)
vignette, with other details and support at the [package
site](https://mc-stan.org/cmdstanr/) along with some key instructions
available in the [Stan resources package
vignette](https://package.epinowcast.org/articles/stan-help.html#toolchain),
but the brief version is:

``` r
# if you not yet installed `epinowcast`, or you installed it without `Suggests` dependencies
install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))
# once `cmdstanr` is installed:
cmdstanr::install_cmdstan()
```

*Note: You can speed up CmdStan installation using the `cores` argument.
If you are installing a particular version of `epinowcast`, you may also
need to install a past version of CmdStan, which you can do with the
`version` argument.*

</details>
<details>
<summary>
Alternative: Docker
</summary>

We also provide a [Docker](https://www.docker.com/get-started/) image
with [`epinowcast` and all dependencies
installed](https://github.com/orgs/epinowcast/packages/container/package/epinowcast).
You can use this image to run `epinowcast` without installing
dependencies.

</details>

## Resources

As you use the package, the documentation available via `?enw_` should
be your first stop for troubleshooting. We also provide a range of other
documentation, case studies, and community spaces to ask (and answer!)
questions:

<details>
<summary>
Package Website
</summary>

The [`epinowcast` website](https://package.epinowcast.org/) includes a
function reference, model outline, and case studies using the package.
The site mainly concerns the release version, but you can also find
documentation for [the latest development
version](https://package.epinowcast.org/dev/).

</details>
<details>
<summary>
R Vignettes
</summary>

We have created [package
vignettes](https://package.epinowcast.org/articles) to help you [get
started
nowcasting](https://package.epinowcast.org/articles/epinowcast.html) and
to [highlight other features with case
studies](https://package.epinowcast.org/articles/germany-age-stratified-nowcasting.html).

</details>
<details>
<summary>
Organisation Website
</summary>

Our [organisation website](https://www.epinowcast.org/) includes links
to other resources, [guest posts](https://www.epinowcast.org/blog.html),
and [seminar schedule](https://www.epinowcast.org/seminars.html) for
both upcoming and past recordings.

</details>
<details>
<summary>
Community Forum
</summary>

Our [community forum](https://community.epinowcast.org/) has areas for
[question and answer](https://community.epinowcast.org/c/interface/15)
and [considering new methods and
tools](https://community.epinowcast.org/c/projects/11), among others. If
you are generally interested in real-time analysis of infectious
disease, you may find this useful even if do not use `epinowcast`.

</details>
<details>
<summary>
Package Analysis Scripts
</summary>

In addition to the vignettes, the package also comes with [example
analyses](https://github.com/epinowcast/epinowcast/tree/main/inst/examples).
These are not as polished as the vignettes, but we typically explore new
features with these and they may help you if you are using a development
version. After installing `epinowcast`, you can find them via:

``` r
list.files(
  system.file("examples", package = "epinowcast"), full.names = TRUE
)
```

</details>

## Contributing

We welcome contributions and new contributors! We particularly
appreciate help on [identifying and identified
issues](https://github.com/epinowcast/epinowcast/issues). Please check
and add to the issues, and/or add a [pull
request](https://github.com/epinowcast/epinowcast/pulls) and see our
[contributing
guide](https://github.com/epinowcast/.github/blob/main/CONTRIBUTING.md)
for more information.

If you need a different underlying model for your work: `epinowcast`
lets you pass your own models! If you do try new model parameterisations
that expand the overall flexibility or improve the defaults, please let
us know either here or on the [community
forum](https://community.epinowcast.org/). We always like to hear about
new use-cases, whether or not they are directed at the core `epinowcast`
applications.

### How to make a bug report or feature request

Please briefly describe your problem and what output you expect in an
[issue](https://github.com/epinowcast/epinowcast/issues). If you have a
question, please don’t open an issue. Instead, ask on our [Q and A
page](https://github.com/epinowcast/epinowcast/discussions/categories/q-a).
See our [contributing
guide](https://github.com/epinowcast/.github/blob/main/CONTRIBUTING.md)
for more information.

### Code of Conduct

Please note that the `epinowcast` project is released with a
[Contributor Code of
Conduct](https://github.com/epinowcast/.github/blob/main/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.

## Citation

If making use of our methodology or the methodology on which ours is
based, please cite the relevant papers from our [model
outline](https://package.epinowcast.org/articles/model.html). If you use
`epinowcast` in your work, please consider citing it with
`citation("epinowcast")`.

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

All contributions to this project are gratefully acknowledged using the
[`allcontributors` package](https://github.com/ropensci/allcontributors)
following the [all-contributors](https://allcontributors.org)
specification. Contributions of any kind are welcome!

### Code

<a href="https://github.com/epinowcast/epinowcast/commits?author=seabbs">seabbs</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=adrian-lison">adrian-lison</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=sbfnk">sbfnk</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=Bisaloo">Bisaloo</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=pearsonca">pearsonca</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=choi-hannah">choi-hannah</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=medewitt">medewitt</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=jamesmbaazam">jamesmbaazam</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=pitmonticone">pitmonticone</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=athowes">athowes</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=jessalynnsebastian">jessalynnsebastian</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=kathsherratt">kathsherratt</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=kaitejohnson">kaitejohnson</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=Lnrivas">Lnrivas</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=natemcintosh">natemcintosh</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=nikosbosse">nikosbosse</a>,
<a href="https://github.com/epinowcast/epinowcast/commits?author=pratikunterwegs">pratikunterwegs</a>

### Issue Authors

<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Ateojcryan">teojcryan</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3AFelixGuenther">FelixGuenther</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Abeansrowning">beansrowning</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Ajbracher">jbracher</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Azsusswein">zsusswein</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Achristinesangphet">christinesangphet</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Arumackaaron">rumackaaron</a>

### Issue Contributors

<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3Ajhellewell14">jhellewell14</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3AGulfa">Gulfa</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3Aparksw3">parksw3</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3ATimTaylor">TimTaylor</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3AWardBrian">WardBrian</a>,
<a href="https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3Ajimrothstein">jimrothstein</a>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->
