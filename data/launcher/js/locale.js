
// var language = window.navigator.userLanguage || window.navigator.language;
// alert(language); //works IE/SAFARI/CHROME/FF

var language = window.navigator.userLanguage || window.navigator.language;
document.webL10n.setLanguage(language);

window.addEventListener('localized', function() {
  document.documentElement.lang = document.webL10n.getLanguage();
  document.documentElement.dir = document.webL10n.getDirection();
}, false);

var _ = document.webL10n.get;

