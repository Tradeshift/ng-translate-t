# ng-translate-t
![coverage-badge][coverage-badge]

[![semantic-release][semantic-release-badge]][semantic-release]
[![Commitizen friendly][commitizen-badge]][commitizen]

Angular 1.x module to provide convenient translation directives.

## The problem
Using translations across views in Angular apps is tedious and error prone with
`$scope` variables, and angular specific with existing libraries like
`angular-translate`.

## This solution
We provide configurable directives, `t` and `t-attrs`, focusing on extracting
the metadata for the translations, and allowing you to specify your own lookup
method.

The directives extract the `text`, dynamic `params`, `context` and `shouldEscape`
from the [attributes](#api).

## Table of contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Installation](#installation)
- [Usage](#usage)
- [API](#api)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Installation
Install via npm
```
npm i @tradeshift/ng-translate-t
```

## Usage
Register the module
```js
// recommended w/ commonJS module:
angular.module('app', [require('ng-translate-t')]);
// UMD / browser use:
angular.module('app', ['ng-translate-t']);
```

Configure your translation provider:
```js
app
  .config($translateProvider => {
    // Set your preferred translation function here:
    $translateProvider.setTranslationFunction((text, params, context, shouldEscape) => {
      // Our translators are lazy, so we translate everything to "42".
      return '42';
    });
  });
```

See the [example](examples/cdn.html) for a demo app.

## API
### `$translateProvider.setTranslationFunction(fn: TranslationFunction): void`
Replaces the `translationFunction` with `fn`. Defaults to `window.t`.

Types:
* `TranslationFunction`: `(text, params, context, shouldEscape): string`

Params:
* `text`: `string` is the extracted string for translation
* `params`: `{[k: string]: string}` are parameters to pass to do e.g. dynamic pluralization
* `context`: `string` gives context to translators and allows different translations of the same
`text` based on context, e.g. whether it's for a form or an image
* `shouldEscape`: `boolean` allows conditional escaping (HTML or other) where needed

### `t` directive
Used to replace the contents (`innerHTML`) of an element with translated strings.

If the element has children, their attributes are replaced with a `ref="1"` count
(in depth-first order), in order to preserve translation hashes when e.g. style attributes change.

Attributes:
* `[t-[param]]`: `string`. Any attribute starting with `t-` will become a `params` key (camelCased),
with the value read from `$scope` under the corresponding key.
* `[t-context]`: `string` passed to `translationFunction` as `context`
* `[t-escape]`: `boolean` passed to `translationFunction` as `shouldEscape`

```html
<t>Translatable string</t>
<div t>Translatable string</div>

<!-- passing down $scope.oranges as orangesCount -->
<div t t-oranges-count="oranges">
  You have {orangesCount} {orangesCount, plural,
    one {orange}
    other {oranges}
}
</div>
```

### `[t-attrs]` directive
Used to replace attributes of an element with translated strings.

Attributes:
* `[t-attrs]`: `string` comma delimited string of attributes to replace with translations.
* `[t-context]`: `string` passed to `translationFunction` as `context`
* `[t-escape]`: `boolean` passed to `translationFunction` as `shouldEscape`

```html
<div t-attrs="title" title="Translatable string"></t>
<img t-attrs="alt,title" title="Translated title" alt="Translated alt" src="#" />
```

## License
ISC. Copyright (c) 2018, [Tradeshift](https://github.com/Tradeshift).

[coverage-badge]: https://img.shields.io/badge/coverage-100%25-brightgreen.svg
[semantic-release]: https://github.com/semantic-release/semantic-release
[semantic-release-badge]: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
[commitizen]: http://commitizen.github.io/cz-cli/
[commitizen-badge]: https://img.shields.io/badge/commitizen-friendly-brightgreen.svg
