import { $, clearEl, escapeHtml } from './utils/dom';
import { delegate } from './utils/events';
import { fetchJson, handleError } from './utils/requests';

function getAssociations(event, target) {
  const { asPath, asTarget } = target.dataset;
  const textarea = $('textarea.js-taginput');
  const tagBox = $(asTarget);
  const tagList = { tags: textarea.value.split(',').map(x => x.trim()) };

  event.preventDefault();
  target.enabled = false;

  fetchJson('POST', asPath, tagList)
    .then(handleError)
    .then(resp => resp.json())
    .then(tags => {
      clearEl(tagBox);

      target.enabled = true;
      tags.forEach(({ label, value }) => {
        const el = `<span class="tag"><a href="#" data-click-addtag data-tag-name="${escapeHtml(value)}">${escapeHtml(label)}</a></span>`;
        tagBox.insertAdjacentHTML('beforeend', el);
      });
    });
}

export function listenAssociations() {
  delegate(document.body, 'click', {'.js-load-associations': getAssociations});
}
