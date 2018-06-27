/**
 *  @jest-environment jsdom
 **/
import angular from 'angular';
import 'angular-mocks';

import translateModule from '../index';

const getValue = el => {
	const ta = document.createElement('textarea');
	// fix html encoding:
	ta.innerHTML = el.html();
	// fix quote escapes:
	const unescaped = ta.value.replace(/"\\"/g, '\\"').replace(/\\""/g, '\\"');
	return unescaped; // JSON.parse(unescaped);
};

const ref = (text, params, context) => JSON.stringify({ text, params, context })

describe('translation directive', () => {
	let helper;
	let $compile;
	let $rootScope;
	let $controller;

	const compileAndDigest = html => {
		const scope = $rootScope.$new();
		const element = $compile(html)(scope);
		scope.$apply();
		return element;
	};

	beforeEach(() => {
		angular.mock.module.sharedInjector();
		angular.mock.module(translateModule, function($translateProvider) {
			$translateProvider.setTranslationFunction(ref);
		});
		angular.mock.inject(
			function(_$compile_, _$rootScope_, _$controller_) {
				$compile = _$compile_;
				$rootScope = _$rootScope_;
				$controller = _$controller_;
			}
		);
	});

	it('replaces innerHTML with lookup', () => {
		const element = compileAndDigest('<div t>Open my app</div>');
		expect(getValue(element)).toEqual(ref('Open my app', {}));
	});

	it('replaces innerHTML with lookup and t-context', () => {
		const element = compileAndDigest('<div t t-context="Hi">Open my app</div>');
		expect(getValue(element)).toEqual(ref('Open my app', {}, 'Hi'));
	});

	it('handles complex strings w/ refs', () => {
		const element = compileAndDigest('<div t>Open my app<span id="1">foo</span> </div>');
		expect(getValue(element)).toEqual(ref('Open my app<span ref="1">foo</span>', {}));
	});

	it('replaces inline whitespaces with single whitespace', () => {
		const element = compileAndDigest(`<p
		class="description"
		t t-context="Messages when no groups available"
>You haven't created any groups yet. Groups are used to organise which companies
		<br>receive which questions. Create a group by clicking the "manage groups"-button
		<br>above
</p>`);
		expect(getValue(element)).toEqual(
			ref(
				'You haven\'t created any groups yet. Groups are used to organise which companies <br ref="1">receive which questions. Create a group by clicking the "manage groups"-button <br ref="2">above',
				{},
				'Messages when no groups available'
			)
		);
	});
});