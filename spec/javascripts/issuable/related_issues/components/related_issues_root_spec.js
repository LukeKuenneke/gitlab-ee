import Vue from 'vue';
import relatedIssuesRoot from '~/issuable/related_issues/components/related_issues_root.vue';

const defaultProps = {
  endpoint: '/foo/bar/issues/1/related_issues',
  currentNamespacePath: 'foo',
  currentProjectPath: 'bar',
};

const issuable1 = {
  id: '200',
  reference: 'foo/bar#123',
  title: 'issue1',
  path: '/foo/bar/issues/123',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/123/related_issues/1',
};

const issuable2 = {
  id: '201',
  reference: 'foo/bar#124',
  title: 'issue1',
  path: '/foo/bar/issues/124',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/124/related_issues/1',
};

describe('RelatedIssuesRoot', () => {
  let RelatedIssuesRoot;
  let vm;

  beforeEach(() => {
    RelatedIssuesRoot = Vue.extend(relatedIssuesRoot);
  });

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('methods', () => {
    describe('onRelatedIssueRemoveRequest', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
        vm.store.setRelatedIssues([issuable1]);
      });

      it('remove related issue and succeeds', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({
            issues: [],
          }), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1.id);

        setTimeout(() => {
          expect(vm.state.relatedIssues).toEqual([]);

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });

      it('remove related issue, fails, and restores to related issues', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 422,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1.id);

        setTimeout(() => {
          expect(vm.state.relatedIssues.length).toEqual(1);
          expect(vm.state.relatedIssues[0].id).toEqual(issuable1.id);

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });
    });

    describe('onShowAddRelatedIssuesForm', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
      });

      it('show add related issues form', () => {
        vm.onShowAddRelatedIssuesForm();

        expect(vm.isFormVisible).toEqual(true);
      });
    });

    describe('onPendingIssueRemoveRequest', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
        vm.store.setpendingReferences([issuable1.reference]);
      });

      it('remove pending related issue', () => {
        expect(vm.state.pendingReferences.length).toEqual(1);

        vm.onPendingIssueRemoveRequest(issuable1.reference);

        expect(vm.state.pendingReferences.length).toEqual(0);
      });
    });

    describe('onPendingFormSubmit', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
      });

      it('submit zero pending issue as related issue', (done) => {
        vm.store.setpendingReferences([]);
        vm.onPendingFormSubmit();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.state.pendingReferences.length).toEqual(0);
            expect(vm.state.relatedIssues.length).toEqual(0);

            done();
          });
        });
      });

      it('submit pending issue as related issue', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({
            issues: [issuable1],
            result: {
              message: 'something was successfully related',
              status: 'success',
            },
          }), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.store.setpendingReferences([issuable1.reference]);
        vm.onPendingFormSubmit();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.state.pendingReferences.length).toEqual(0);
            expect(vm.state.relatedIssues.length).toEqual(1);
            expect(vm.state.relatedIssues[0].id).toEqual(issuable1.id);

            done();

            Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
          });
        });
      });

      it('submit multiple pending issues as related issues', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({
            issues: [issuable1, issuable2],
            result: {
              message: 'something was successfully related',
              status: 'success',
            },
          }), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.store.setpendingReferences([issuable1.reference, issuable2.reference]);
        vm.onPendingFormSubmit();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.state.pendingReferences.length).toEqual(0);
            expect(vm.state.relatedIssues.length).toEqual(2);
            expect(vm.state.relatedIssues[0].id).toEqual(issuable1.id);
            expect(vm.state.relatedIssues[1].id).toEqual(issuable2.id);

            done();

            Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
          });
        });
      });
    });

    describe('onPendingFormCancel', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
        vm.isFormVisible = true;
        vm.inputValue = 'foo';
      });

      it('when canceling and hiding add issuable form', () => {
        vm.onPendingFormCancel();

        expect(vm.isFormVisible).toEqual(false);
        expect(vm.inputValue).toEqual('');
        expect(vm.state.pendingReferences.length).toEqual(0);
      });
    });

    describe('fetchRelatedIssues', () => {
      const interceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([issuable1, issuable2]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();

        Vue.http.interceptors.push(interceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('fetching related issues', (done) => {
        vm.fetchRelatedIssues();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.state.relatedIssues.length).toEqual(2);
            expect(vm.state.relatedIssues[0].id).toEqual(issuable1.id);
            expect(vm.state.relatedIssues[1].id).toEqual(issuable2.id);

            done();
          });
        });
      });
    });

    describe('onInput', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
      });

      it('fill in issue number reference and adds to pending related issues', () => {
        const input = '#123 ';
        vm.onInput(input, input.length);

        expect(vm.state.pendingReferences.length).toEqual(1);
        expect(vm.state.pendingReferences[0]).toEqual('#123');
      });

      it('fill in with full reference', () => {
        const input = 'asdf/qwer#444 ';
        vm.onInput(input, input.length);

        expect(vm.state.pendingReferences.length).toEqual(1);
        expect(vm.state.pendingReferences[0]).toEqual('asdf/qwer#444');
      });

      it('fill in with issue link', () => {
        const link = 'http://localhost:3000/foo/bar/issues/111';
        const input = `${link} `;
        vm.onInput(input, input.length);

        expect(vm.state.pendingReferences.length).toEqual(1);
        expect(vm.state.pendingReferences[0]).toEqual(link);
      });

      it('fill in with multiple references', () => {
        const input = 'asdf/qwer#444 #12 ';
        vm.onInput(input, input.length);

        expect(vm.state.pendingReferences.length).toEqual(2);
        expect(vm.state.pendingReferences[0]).toEqual('asdf/qwer#444');
        expect(vm.state.pendingReferences[1]).toEqual('#12');
      });

      it('fill in with some invalid things', () => {
        const input = 'something random ';
        vm.onInput(input, input.length);

        expect(vm.state.pendingReferences.length).toEqual(2);
        expect(vm.state.pendingReferences[0]).toEqual('something');
        expect(vm.state.pendingReferences[1]).toEqual('random');
      });

      it('fill in invalid and some legit references', () => {
        const input = 'something random #123 ';
        vm.onInput(input, input.length);

        expect(vm.state.pendingReferences.length).toEqual(3);
        expect(vm.state.pendingReferences[0]).toEqual('something');
        expect(vm.state.pendingReferences[1]).toEqual('random');
        expect(vm.state.pendingReferences[2]).toEqual('#123');
      });

      it('keep reference piece in input while we are touching it', () => {
        const input = 'a #123 b ';
        vm.onInput(input, 3);

        expect(vm.state.pendingReferences.length).toEqual(2);
        expect(vm.state.pendingReferences[0]).toEqual('a');
        expect(vm.state.pendingReferences[1]).toEqual('b');
      });
    });

    describe('onBlur', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
      });

      it('add valid reference to pending when blurring', () => {
        const input = '#123';
        vm.onBlur(input);

        expect(vm.state.pendingReferences.length).toEqual(1);
        expect(vm.state.pendingReferences[0]).toEqual('#123');
      });

      it('add any valid references to pending when blurring', () => {
        const input = 'asdf #123';
        vm.onBlur(input);

        expect(vm.state.pendingReferences.length).toEqual(2);
        expect(vm.state.pendingReferences[0]).toEqual('asdf');
        expect(vm.state.pendingReferences[1]).toEqual('#123');
      });
    });
  });
});
