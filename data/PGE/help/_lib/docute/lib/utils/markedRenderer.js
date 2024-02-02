import marked from './marked';
import { slugify } from '.';
export default (function (hooks) {
  var renderer = new marked.Renderer();
  var slugs = [];

  renderer.heading = function (text, level, raw) {
    var env = this.options.env;
    var slug = slugify(raw);
    slugs.push(slug);
    var sameSlugCount = slugs.filter(function (v) {
      return v === slug;
    }).length;

    if (sameSlugCount > 1) {
      slug += "-" + sameSlugCount;
    }

    if (level === 1) {
      env.title = text; // Remove h1 header

      return '';
    }

    if (level === 2) {
      env.headings.push({
        level: level,
        raw: raw,
        // Remove trailing HTML
        text: raw.replace(/<.*>\s*$/g, ''),
        slug: slug
      });
    }

    var tag = "h" + level;
    return "<" + tag + " class=\"markdown-header\" id=\"" + slug + "\">\n    <router-link class=\"header-anchor\" :to=\"{hash:'" + slug + "'}\">\n      <svg class=\"anchor-icon\" viewBox=\"0 0 16 16\" version=\"1.1\" width=\"16\" height=\"16\"><path fill-rule=\"evenodd\" d=\"M4 9h1v1H4c-1.5 0-3-1.69-3-3.5S2.55 3 4 3h4c1.45 0 3 1.69 3 3.5 0 1.41-.91 2.72-2 3.25V8.59c.58-.45 1-1.27 1-2.09C10 5.22 8.98 4 8 4H4c-.98 0-2 1.22-2 2.5S3 9 4 9zm9-3h-1v1h1c1 0 2 1.22 2 2.5S13.98 12 13 12H9c-.98 0-2-1.22-2-2.5 0-.83.42-1.64 1-2.09V6.25c-1.09.53-2 1.84-2 3.25C6 11.31 7.55 13 9 13h4c1.45 0 3-1.69 3-3.5S14.5 6 13 6z\"></path></svg>\n    </router-link>\n    " + text + "</" + tag + ">";
  }; // Disable template interpolation in code


  renderer.codespan = function (text) {
    return "<code v-pre>" + text + "</code>";
  };

  var origCode = renderer.code;

  renderer.code = function (code, lang, escaped, opts) {
    opts = opts || {};
    var env = this.options.env;

    if (opts.mixin) {
      env.mixins.push(code);
      return '';
    }

    var res = origCode.call(this, code, lang, escaped);

    if (!opts.interpolate) {
      res = res.replace(/^<pre>/, '<pre v-pre>');
    }

    if (opts.highlight) {
      var codeMask = code.split('\n').map(function (v, i) {
        i += 1;
        var shouldHighlight = opts.highlight.some(function (number) {
          if (typeof number === 'number') {
            return number === i;
          }

          if (typeof number === 'string') {
            var _number$split$map = number.split('-').map(Number),
                start = _number$split$map[0],
                end = _number$split$map[1];

            return i >= start && (!end || i <= end);
          }

          return false;
        });
        var escapedLine = v ? marked.escape(v) : '&#8203;';
        return shouldHighlight ? "<span class=\"code-line highlighted\">" + escapedLine + "</span>" : "<span class=\"code-line\">" + escapedLine + "</span>";
      }).join('');
      res += "<div" + (opts.interpolate ? '' : ' v-pre') + " class=\"code-mask\">" + codeMask + "</div>";
    }

    return "<div data-lang=\"" + (lang || '') + "\" class=\"pre-wrapper\">" + res + "</div>";
  };

  return hooks.process('extendMarkedRenderer', renderer);
});