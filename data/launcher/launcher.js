/*global Launcher, onInitLauncher, Promise, document, XMLHttpRequest, console, resolve, reject, confirm*/


var launcherLoaded = false;
function checkLoaded() {
    if(!launcherLoaded) {
      window.setTimeout(checkLoaded, 200);
    } else {
      document.getElementById("loaderCover").style.display = "none";
    }
}
window.onload = checkLoaded;

onInitLauncher = function() {
	Launcher.getEpisodeInfo("launcher", "info.json", function(episodeData) {
		var keyboardMap = [
			"", // [0]
			"", // [1]
			"", // [2]
			"CNCL", // [3]
			"", // [4]
			"", // [5]
			"HELP", // [6]
			"", // [7]
			"BCKS", // [8]
			"TAB", // [9]
			"", // [10]
			"", // [11]
			"CLR", // [12]
			"ENTR", // [13]
			"ENTRS", // [14]
			"", // [15]
			"SHFT", // [16]
			"CTRL", // [17]
			"ALT", // [18]
			"PAUS", // [19]
			"CAPS", // [20]
			"KANA", // [21]
			"EISU", // [22]
			"JNJA", // [23]
			"FIN", // [24]
			"HNJA", // [25]
			"", // [26]
			"ESC", // [27]
			"CONV", // [28]
			"NONC", // [29]
			"ACC", // [30]
			"MODE", // [31]
			"SPACE", // [32]
			"PGUP", // [33]
			"PGDWN", // [34]
			"END", // [35]
			"HOME", // [36]
			"LEFT", // [37]
			"UP", // [38]
			"RIGHT", // [39]
			"DOWN", // [40]
			"SEL", // [41]
			"PRNT", // [42]
			"EXE", // [43]
			"PRNT", // [44]
			"INS", // [45]
			"DEL", // [46]
			"", // [47]
			"0", // [48]
			"1", // [49]
			"2", // [50]
			"3", // [51]
			"4", // [52]
			"5", // [53]
			"6", // [54]
			"7", // [55]
			"8", // [56]
			"9", // [57]
			":", // [58]
			";", // [59]
			"<", // [60]
			"=", // [61]
			">", // [62]
			"?", // [63]
			"@", // [64]
			"A", // [65]
			"B", // [66]
			"C", // [67]
			"D", // [68]
			"E", // [69]
			"F", // [70]
			"G", // [71]
			"H", // [72]
			"I", // [73]
			"J", // [74]
			"K", // [75]
			"L", // [76]
			"M", // [77]
			"N", // [78]
			"O", // [79]
			"P", // [80]
			"Q", // [81]
			"R", // [82]
			"S", // [83]
			"T", // [84]
			"U", // [85]
			"V", // [86]
			"W", // [87]
			"X", // [88]
			"Y", // [89]
			"Z", // [90]
			"OS", // [91] Windows Key (Windows) or Command Key (Mac)
			"", // [92]
			"MENU", // [93]
			"", // [94]
			"SLP", // [95]
			"0", // [96]
			"1", // [97]
			"2", // [98]
			"3", // [99]
			"4", // [100]
			"5", // [101]
			"6", // [102]
			"7", // [103]
			"8", // [104]
			"9", // [105]
			"*", // [106]
			"+", // [107]
			"SEP", // [108]
			"-", // [109]
			".", // [110]
			"/", // [111]
			"F1", // [112]
			"F2", // [113]
			"F3", // [114]
			"F4", // [115]
			"F5", // [116]
			"F6", // [117]
			"F7", // [118]
			"F8", // [119]
			"F9", // [120]
			"F10", // [121]
			"F11", // [122]
			"F12", // [123]
			"F13", // [124]
			"F14", // [125]
			"F15", // [126]
			"F16", // [127]
			"F17", // [128]
			"F18", // [129]
			"F19", // [130]
			"F20", // [131]
			"F21", // [132]
			"F22", // [133]
			"F23", // [134]
			"F24", // [135]
			"", // [136]
			"", // [137]
			"", // [138]
			"", // [139]
			"", // [140]
			"", // [141]
			"", // [142]
			"", // [143]
			"NUM", // [144]
			"SCROLL", // [145]
			"JISHO", // [146]
			"MASSHOU", // [147]
			"TOUROKU", // [148]
			"LOYA", // [149]
			"ROYA", // [150]
			"", // [151]
			"", // [152]
			"", // [153]
			"", // [154]
			"", // [155]
			"", // [156]
			"", // [157]
			"", // [158]
			"", // [159]
			"^", // [160]
			"!", // [161]
			"\"", // [162]
			"#", // [163]
			"$", // [164]
			"%", // [165]
			"&", // [166]
			"_", // [167]
			"(", // [168]
			")", // [169]
			"*", // [170]
			"+", // [171]
			"|", // [172]
			"-", // [173]
			"{", // [174]
			"}", // [175]
			"~", // [176]
			"", // [177]
			"", // [178]
			"", // [179]
			"", // [180]
			"MUTE", // [181]
			"VDOWN", // [182]
			"VUP", // [183]
			"", // [184]
			"", // [185]
			";", // [186]
			"=", // [187]
			",", // [188]
			"-", // [189]
			".", // [190]
			"/", // [191]
			"\'", // [192]
			"", // [193]
			"", // [194]
			"", // [195]
			"", // [196]
			"", // [197]
			"", // [198]
			"", // [199]
			"", // [200]
			"", // [201]
			"", // [202]
			"", // [203]
			"", // [204]
			"", // [205]
			"", // [206]
			"", // [207]
			"", // [208]
			"", // [209]
			"", // [210]
			"", // [211]
			"", // [212]
			"", // [213]
			"", // [214]
			"", // [215]
			"", // [216]
			"", // [217]
			"", // [218]
			"[", // [219]
			"\\", // [220]
			"]", // [221]
			"\'", // [222]
			"", // [223]
			"META", // [224]
			"ALTG", // [225]
			"", // [226]
			"HELP", // [227]
			"00", // [228]
			"", // [229]
			"CLEAR", // [230]
			"", // [231]
			"", // [232]
			"RESET", // [233]
			"JUMP", // [234]
			"PA1", // [235]
			"PA2", // [236]
			"PA3", // [237]
			"WCTRL", // [238]
			"CUSEL", // [239]
			"ATTN", // [240]
			"FIN", // [241]
			"COPY", // [242]
			"AUTO", // [243]
			"ENLW", // [244]
			"BTAB", // [245]
			"ATTN", // [246]
			"CRSEL", // [247]
			"EXSEL", // [248]
			"EREOF", // [249]
			"PLAY", // [250]
			"ZOOM", // [251]
			"", // [252]
			"PA1", // [253]
			"CLR", // [254]
			"" // [255]
		];

		var firstEmptySaveSlot = 1;

		function isSecondVersionNewer(a, b) {
			if (a === undefined || b === undefined) {
				return false;
			}
			var i = 0;
			while (true) {
				if (a[i] === undefined && b[i] === undefined) {
					return false;
				} // Ran out of digits, *not* newer
				if (b[i] === undefined) {
					return false;
				} // Equal so far and second is shorter, *not* newer
				if (a[i] === undefined) {
					return true;
				} // Equal so far and second is longer, newer
				if (b[i] > a[i]) {
					return true;
				} // Equal so far and second digit is higher, newer
				i = i + 1;
			}
			return false;
		}

		function showPosts() {
			var xhttp = new XMLHttpRequest();
			xhttp.onreadystatechange = function() {
				if (xhttp.readyState === 4 && xhttp.status !== 200){
					document.getElementById("rightColumn").firstChild.innerHTML = _("ErrorLoadingFeed");
				}else if (xhttp.readyState === 4 && xhttp.status === 200) {
					while (document.getElementById("rightColumn").firstChild) {
						document.getElementById("rightColumn").removeChild(document.getElementById("rightColumn").firstChild);
					}
					var parser = new DOMParser();
					var xmlDoc = parser.parseFromString(xhttp.responseText, "text/xml");
					var posts = document.createElement("div");
					var arrayOfItems = Array.from(xmlDoc.getElementsByTagName("item"));
					var expression = /[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?/gi;
					var expression2 = /<p class="link-more">.*/gi;
					var expression3 = /View post on imgur.com/gi;
					var expression4 = /<img src="" \/>/gi;
					var expression5 = /<img.* \/>/gi;
					arrayOfItems.forEach(function(someItem) {
						postEntry = document.createElement("div");
						postEntry.setAttribute("class", "rssEntry");
						var somePostLink = document.createElement("a");
						somePostLink.setAttribute("href", someItem.querySelector("link").textContent);
						somePostLink.setAttribute("class", "rssLink");
						somePostLink.appendChild(document.createTextNode(someItem.querySelector("title").textContent));
						somePostDescriptionBox = document.createElement("div");
						somePostDescriptionBox.setAttribute("class", "descriptionBox");
						if (someItem.querySelector("description")) {
							var someDescription = someItem.querySelector("description").textContent;
							var someNewParser = new DOMParser();
							var someImage = someNewParser.parseFromString(someDescription, "text/html").querySelector(".wp-post-image");
							if (someImage) {
								/*var entryThumbnailDiv = document.createElement("div");
								entryThumbnailDiv.setAttribute("class", "descriptionThumbnailDiv");
								var thumbLink = document.createElement("a");
								thumbLink.setAttribute("href", someItem.querySelector("link").textContent);
								thumbLink.setAttribute("class", "descriptionThumbnailLink");
								var entryThumbnail = document.createElement("img");
								entryThumbnail.src = someImage.src;
								var entryHoverDiv = document.createElement("div");
								entryHoverDiv.setAttribute("class", "descriptionThumbnailOverlay");
								thumbLink.appendChild(entryThumbnail);
								entryThumbnailDiv.appendChild(thumbLink);
								entryThumbnailDiv.appendChild(entryHoverDiv);
								somePostDescriptionBox.appendChild(entryThumbnailDiv);*/
								
								var entryThumbnailDiv = document.createElement("div");
								entryThumbnailDiv.setAttribute("class", "descriptionThumbnailDiv");
								var thumbLink = document.createElement("a");
								thumbLink.setAttribute("href", someItem.querySelector("link").textContent);
								var entryThumbnail = document.createElement("img");
								entryThumbnail.src = someImage.src;
								var entryHoverDiv = document.createElement("div");
								entryHoverDiv.setAttribute("class", "descriptionThumbnailOverlay");
								entryThumbnailDiv.appendChild(entryThumbnail);
								entryThumbnailDiv.appendChild(entryHoverDiv);
								entryThumbnailDiv.appendChild(thumbLink);
								somePostDescriptionBox.appendChild(entryThumbnailDiv);
							}
							somePostDescriptionBox.innerHTML += someDescription.replace(expression3, "").replace(expression2, "").replace(expression, "").replace(expression4, "").replace(expression5, "").substring(0, 150) + "...";
						} else {
							somePostDescriptionBox.appendChild(document.createTextNode(_("NoDescription")));
						}
						postEntry.appendChild(somePostLink);
						postEntry.appendChild(somePostDescriptionBox);
						posts.appendChild(postEntry);
					});
					
					if (posts.lastChild) {
						posts.lastChild.style.borderBottom = "none";
					}
					document.getElementById("rightColumn").appendChild(posts);
				}
			};
			xhttp.open("GET", "http://codehaus.wohlsoft.ru/blog/feed/?" + (new Date()).getTime(), true);
			xhttp.send();
		}

		function parseIniString(data) {
			var regex = {
				section: /^\s*\[\s*([^\]]*)\s*\]\s*$/,
				param: /^\s*([^=]+?)\s*=\s*(.*?)\s*$/,
				comment: /^\s*;.*$/
			};
			var value = {};
			var lines = data.split(/[\r\n]+/);
			var section = null;
			var match;
			lines.forEach(function(line) {
				if (regex.comment.test(line)) {
					return;
				} else if (regex.param.test(line)) {
					match = line.match(regex.param);
					if (section) {
						value[section][match[1]] = match[2];
					} else {
						value[match[1]] = match[2];
					}
				} else if (regex.section.test(line)) {
					match = line.match(regex.section);
					value[match[1]] = {};
					section = match[1];
				} else if (line.length == 0 && section) {
					section = null;
				}
			});
			return value;
		}

		function getLocalFile(url) {
			return new Promise(function(resolve, reject) {
				var xhttp = new XMLHttpRequest();
				xhttp.onreadystatechange = function() {
					if (xhttp.readyState === 4 && xhttp.status === 0) {
						var response = xhttp.response;
						if (response.length > 0) {
							resolve(response);
						} else {
							reject(Error(_("ErrorNoAchievementFolder")));
						}
					}
				};
				xhttp.open("GET", url, true);
				xhttp.send();
			});
		}

		function getProgressJson(url) {
			return new Promise(function(resolve, reject) {
				var xhttp = new XMLHttpRequest();
				xhttp.onreadystatechange = function() {
					if (xhttp.readyState === 4 && xhttp.status === 0) {
						var response = xhttp.response;
						if (response.length > 0) {
							resolve(response);
						} else {
							resolve(null);
						}
					}
				};
				xhttp.open("GET", url, true);
				xhttp.onerror = function() {
					resolve(null);
				}
				xhttp.send();
			});
		}

		var achievementListsByEpisode = {}
		var achievementIconsByEpisode = {}

		document.getElementById("achievementIcons").appendChild(document.createElement("div"));
		document.getElementById("achievementLists").appendChild(document.createElement("div"));
		
		function updateAchievementCenterContents(episodeName) {
			var achievementCenterBox = document.getElementById("achievementIcons");
			var achievementCenterListBox = document.getElementById("achievementLists");
			achievementCenterListBox.style.position = "relative";
			if (achievementIconsByEpisode[episodeName] != null) {
				achievementCenterListBox.replaceChild(achievementListsByEpisode[episodeName], achievementCenterListBox.firstChild);
				achievementCenterBox.replaceChild(achievementIconsByEpisode[episodeName], achievementCenterBox.firstChild);
			} else {
				//Shouldn't ever get here, but just in case.
				var divdoc = document.createElement("div");
				divdoc.style.lineHeight = "24px";
				divdoc.style.fontSize = "24px";
				divdoc.style.color = "black";
				divdoc.style.textContent = _("NoAchievements");
				divdoc.style.fontStyle = "italic";
				divdoc.appendChild(document.createTextNode(_("NoAchievements")));
				achievementCenterListBox.replaceChild(divdoc, achievementCenterListBox.firstChild);
				achievementCenterBox.replaceChild(document.createElement("div"), achievementCenterBox.firstChild);
			}
		}
		
		function trimQuotes(s) {
			var match = s.match(/^([\'\"])(.*)\1$/);
			if (match) {
				return match[2];
			} else {
				return s;
			}
		}

		function addToAchievementCenter(someJsonObject, someParsedIniList, episode, episodeIdentifier, maxID, validIDs) {
			var episodeEntry = document.createElement("div");
			episodeEntry.setAttribute("style", "achievementEpisodeIconEntry");
			episodeEntry.setAttribute("data-identifier", episodeIdentifier);
			episodeEntry.style.width = "auto";
			//episodeEntry.style.maxWidth = "256px";
			var episodeIcon = document.createElement("div");
			episodeIcon.setAttribute("style", "achievementEpisodeIcon");
			var episodeIconImage = document.createElement("img");
			if (episode.episodeIcon) {
				episodeIconImage.setAttribute("src", "../worlds/" + episode.directoryName + "/launcher/" + episode.episodeIcon);
			} else {
				episodeIconImage.setAttribute("src", "default/icon.png");
			}
			episodeIconImage.style.width = "100%";
			episodeIconImage.style.imageRendering = "pixelated";
			episodeIcon.appendChild(episodeIconImage);
			episodeEntry.appendChild(episodeIcon);
			//achievementCenterMasterBox.appendChild(episodeEntry);
			var episodeTitle = document.createElement("div");
			episodeTitle.setAttribute("class", "achievementEpisodeTitle");
			episodeTitle.appendChild(document.createTextNode(episode.title));
			episodeEntry.appendChild(episodeTitle);

			var episodeAchievementProgress = document.createElement("div");
			episodeAchievementProgress.setAttribute("id", "progressBarBackground");
			episodeEntry.appendChild(episodeAchievementProgress);
			var theAchievementList = document.createElement("div");
			theAchievementList.setAttribute("class", "achievementList");
			theAchievementList.setAttribute("id", "entry" + episodeIdentifier);
			var numberOfAchievements = 0;
			var numberOfCompletedAchievements = 0;
			
			var j = 0;
			for (var i = 1; i <= maxID; i = i + 1) {
				var obj;
				if (someJsonObject != null) {
					obj = someJsonObject[i.toString()];
					if (validIDs[i.toString()] !== true) {
						continue;
					}
				}
				numberOfAchievements ++;

				var achievementEntry = document.createElement("div");
				achievementEntry.setAttribute("class", "individualAchievement");
				
				var completed = false;
				
				if (obj != null && obj.c) {
					completed = true;
					numberOfCompletedAchievements++;
					achievementEntry.style.backgroundColor = "darkgreen";
				}
				
				var achievementTitle = document.createElement("div");
				achievementTitle.setAttribute("class", "achievementTitle");
				var achDescContainer = document.createElement("div");
				achDescContainer.style.display = "flex";

				var achInfoLeft = document.createElement("div");
				achInfoLeft.style.float = "left";

				var achIcon = document.createElement("img");
				achIcon.style.display = "flex";
				achIcon.style.float = "right";
				achIcon.style.width = "64px";
				achIcon.style.height = "64px";
				achIcon.style.margin = "4px";  
				if (episode.noAchievementBorders) {
					achIcon.style.border = "none";
				} else {
					achIcon.style.border = "2px solid #00000044"; 
				}				
				achIcon.style.marginLeft = "auto";
				achIcon.style.imageRendering = "pixelated";
				achIcon.name = i;
				
				if (!completed) {
					achIcon.setAttribute("src", "../worlds/" + episode.directoryName + "/achievements/ach-" + i + "l.png");
					achIcon.onerror = function() {
						this.onerror = function() {
							this.setAttribute("src", "../graphics/hardcoded/hardcoded-55.png");
							this.onerror = null;
						}
						this.setAttribute("src", "../worlds/" + episode.directoryName + "/achievements/ach-" + (this.name) + ".png");
						this.setAttribute("class", "lockedAchievementImage");
					}
				} else {
					achIcon.setAttribute("src", "../worlds/" + episode.directoryName + "/achievements/ach-" + i + ".png");
					achIcon.onerror = function() {
						this.setAttribute("src", "../graphics/hardcoded/hardcoded-55.png");
						this.onerror = null;
					}
				}

				var achievementDescription = document.createElement("div");
				achievementDescription.setAttribute("class", "overallAchievementDescription");
				if (!completed && someParsedIniList[j].hidden) {
					achievementEntry.style.backgroundColor = "#444466";
					achievementTitle.appendChild(document.createTextNode(_("HiddenAchievement")));
					var achievementDescriptionDiv = document.createElement("div");
					achievementDescriptionDiv.setAttribute("class", "achievementDescriptionDiv");
					achievementDescriptionDiv.appendChild(document.createTextNode(_("HiddenAchievementDesc")));
					achievementDescription.appendChild(achievementDescriptionDiv);
				} else {
					achievementTitle.appendChild(document.createTextNode(trimQuotes(someParsedIniList[j].name)));
					if (completed && (someParsedIniList[j]["collected-description"] || someParsedIniList[j]["collected-desc"])) {
						var achievementDescriptionDiv = document.createElement("div");
						achievementDescriptionDiv.setAttribute("class", "achievementDescriptionDiv");
						var descriptionString = someParsedIniList[j]["collected-desc"];
						if (someParsedIniList[j]["collected-description"]) {
							descriptionString = someParsedIniList[j]["collected-description"];
						}
						achievementDescriptionDiv.appendChild(document.createTextNode(trimQuotes(descriptionString)));
						achievementDescription.appendChild(achievementDescriptionDiv);
					}else if (someParsedIniList[j].description || someParsedIniList[j].desc) {
						var achievementDescriptionDiv = document.createElement("div");
						achievementDescriptionDiv.setAttribute("class", "achievementDescriptionDiv");
						var descriptionString = someParsedIniList[j].desc;
						if (someParsedIniList[j].description) {
							descriptionString = someParsedIniList[j].description;
						}
						achievementDescriptionDiv.appendChild(document.createTextNode(trimQuotes(descriptionString)));
						achievementDescription.appendChild(achievementDescriptionDiv);
					}
				}
				var listOfKeys = Object.keys(someParsedIniList[j]);
				var listOfConditions = document.createElement("ul");
				listOfConditions.setAttribute("class", "listOfConditions");
				listOfConditions.style.margin = "0px";
				if (completed || !someParsedIniList[j].hidden) {
					listOfKeys.forEach(function(keyName) {
						if (keyName.match("condition-") && !keyName.match("desc")) {
							if (someParsedIniList[j][keyName + "-desc"]) {
								var toPush = {};
								toPush.conditionCounter = keyName.replace("condition-", "");
								var someConditionDescription = document.createElement("li");
								someConditionDescription.setAttribute("class", "conditionDescription");
								toPush.conditionDescription = trimQuotes(someParsedIniList[j][keyName + "-desc"]);
							

								var textelement = document.createElement("div");
								textelement.style.float = "left";
								textelement.style.wordWrap = "break-word";
								textelement.style.display = "flex";
								textelement.appendChild(document.createTextNode(toPush.conditionDescription));

								someConditionDescription.appendChild(textelement);

								var completed = false;
								
								var checkmarker = document.createElement("div");
								checkmarker.style.float = "right";
								checkmarker.style.display = "flex";
								checkmarker.style.maxWidth = "200px";
								checkmarker.style.marginLeft = "4px";
								checkmarker.style.paddingTop = "2px";
								checkmarker.style.paddingRight = "2px";
								someConditionDescription.appendChild(checkmarker);

								if (!isNaN(someParsedIniList[j][keyName])) {
									var progress = 0;
									var maxprogress = someParsedIniList[j][keyName];
									if (obj != null && obj[toPush.conditionCounter] != null) {
										progress = obj[toPush.conditionCounter].v;
									}
									var conditionElement = document.createElement("div");
									conditionElement.setAttribute("id", "progressBarBackground");
									conditionElement.style.float = "right";
									conditionElement.style.marginLeft = "4px";
									
									checkmarker.style.width = "25%";
									checkmarker.style.minWidth = "64px";
									
									progress = Math.min(progress, maxprogress);
	
									var pBar = document.createElement("div");
									pBar.setAttribute("id", "progressBarFill");
									var pprog = Math.floor(100 * (progress/maxprogress));
									pBar.style.width = pprog + "%";
									conditionElement.appendChild(pBar);

									var pnum = document.createElement("div");
									pnum.setAttribute("id", "progressText");
									pnum.appendChild(document.createTextNode(progress + "/" + maxprogress));
									conditionElement.appendChild(pnum);

									checkmarker.appendChild(conditionElement);

									completed = progress >= maxprogress;

								} else {
									var conditionElement = document.createElement("div");
									conditionElement.style.float = "right";
									checkmarker.appendChild(conditionElement);

									if (obj != null && obj[toPush.conditionCounter] != null) {
										completed = obj[toPush.conditionCounter].v;
									}
								}

								if (completed) {
									var conditionElement = document.createElement("img");
									conditionElement.setAttribute("src", "checkbox.png");
									conditionElement.style.height = "16px";
									conditionElement.style.float = "right";
									checkmarker.insertBefore(conditionElement, checkmarker.firstChild);
								}

								listOfConditions.appendChild(someConditionDescription);
							} 
						}
					});
				}
				achInfoLeft.appendChild(achievementTitle);
				achInfoLeft.appendChild(achievementDescription);
				achDescContainer.appendChild(achInfoLeft);
				achDescContainer.appendChild(achIcon);
				achievementEntry.appendChild(achDescContainer);
				if (listOfConditions.children.length > 0) {
					var conditionHeader = document.createElement("div");
					conditionHeader.setAttribute("class", "conditionHeader");
					conditionHeader.appendChild(document.createTextNode(_("AchievementConditions")+":"));
					achievementEntry.appendChild(conditionHeader);
					achievementEntry.appendChild(listOfConditions);
				}
				theAchievementList.appendChild(achievementEntry);
				
				j++;
			}

			var episodeAchProgBar = document.createElement("div");
			episodeAchProgBar.setAttribute("id", "progressBarFill");
			var progress = Math.floor(100 * (numberOfCompletedAchievements/numberOfAchievements));
			episodeAchProgBar.style.width = progress + "%";
			episodeAchievementProgress.appendChild(episodeAchProgBar);

			var progressNumber = document.createElement("div");
			progressNumber.setAttribute("id", "progressText");
			progressNumber.appendChild(document.createTextNode(numberOfCompletedAchievements + "/" + numberOfAchievements));
			episodeAchievementProgress.appendChild(progressNumber);

			achievementListsByEpisode[episodeIdentifier] = theAchievementList;
			achievementIconsByEpisode[episodeIdentifier] = episodeEntry;
			
			
			//Need to do this here to guarantee the trophy icon is correctly displayed when the launcher starts
			var achievementsButton = document.getElementById("trophyIcon");
			
			if (achievementIconsByEpisode[parseInt(document.getElementById("currentEpisode").value)] != null) {
				achievementsButton.style.minWidth = "24px";
				achievementsButton.style.width = "2vw";
				achievementsButton.style.padding = "5px";
			} else {
				achievementsButton.style.minWidth = "0";
				achievementsButton.style.width = "0";
				achievementsButton.style.padding = "0";
			}
		}

		function listLocalFiles(response, prefix, suffix, doFloor) {
			var parser = new DOMParser();
			var htmlDoc = parser.parseFromString(response, "text/html");
			var listOfScripts = htmlDoc.getElementsByTagName("script");
			var finalList = [];
			finalList.length = listOfScripts.length;
			var length = 0;
			var highestIndex = 0;
			var regex = new RegExp(prefix + '[\\d]+' + suffix);
			for (i = 0; i < listOfScripts.length; i = i + 1) {
				if (regex.test(listOfScripts[i].innerHTML)) {
					var k = listOfScripts[i].innerHTML.match(/[\d]+/)-1;
					finalList[k] = listOfScripts[i].innerHTML.split(",")[1].replace(/\"/gi, "");
					length++;
					highestIndex = Math.max(highestIndex, k+1)
				}
			}
			if (doFloor) {
				for (i=0; i<highestIndex; i = i + 1) {
					if (finalList[i] == null) {
						for (j = i+1; j < highestIndex; j = j + 1) {
							if (finalList[j] != null) {
								finalList[i] = finalList[j]
								break;
							}
						}
					}
				}
				finalList.length = length;
			}
			return finalList;
		}

		function onOff(someElement, cookie) {
			if (someElement.style.display === "block") {
				someElement.style.display = "none";
				localStorage.setItem(cookie, "false");
			} else {
				someElement.style.display = "block";
				localStorage.setItem(cookie, "true");
			}
		}
		
		function disableOther(toEnableId) {
			document.getElementById("middleColumn").querySelectorAll(":scope > div:not(.otherStuff), iframe").forEach(function(someDiv) {
				someDiv.style.display = "none";
				document.getElementById("iframer").style.display = "flex";
			});
		}
		
		function toggleOther(toEnableId) {
			document.getElementById("middleColumn").querySelectorAll(":scope > div:not(.otherStuff), iframe").forEach(function(someDiv) {
				if (someDiv.id === toEnableId) {
					if (someDiv.style.display === "flex") {
						someDiv.style.display = "none";
						document.getElementById("iframer").style.display = "flex";
					} else {
						someDiv.style.display = "flex";
					}
				} else {
					someDiv.style.display = "none";
				}
			});
		}

		function manageBottomPanel(toActivate, toGray) {
			document.getElementById("controlSection").querySelectorAll(":scope > div").forEach(function(someDiv) {
				if (someDiv.id === toActivate) {
					someDiv.style.display = "flex";
				} else {
					someDiv.style.display = "none";
				}
			});
		}
		
		function getStarString(episode, plural) {
			var s;
			if (plural && episode.collectibles) {
				s = episode.collectibles;
			} else if (episode.collectible) {
				s = episode.collectible;
			} else if (episode.collectibles) {
				s = episode.collectibles;
			} else if (plural) {
				return _("StarsN");
			} else {
				return _("StarN");
			}
			
			return s.charAt(0).toUpperCase() + s.substring(1);
		}

		function selectEpisodeById(i) {
			var episode = episodeData[i];
			var iframe = document.getElementById("iframer");

			// Remove existing iframe load listeners
			if (iframeOnLoadHandler != null)
			{
				iframe.removeEventListener("load", iframeOnLoadHandler);
			}

			iframeOnLoadHandler = (function() {
				var doc = iframe.contentDocument;
				populateEpisodeTemplate(episode, doc);
			});
			iframe.addEventListener("load", iframeOnLoadHandler);
			// Set iframe SRC
			if (episode.mainPage) {
				// If the episode defines a main page, use it
				iframe.src = "../worlds/" + episode.directoryName + "/launcher/" + episode.mainPage;
			} else {
				// Otherwise... Fun stuff!
				iframe.src = "default/index.html";
			}
			
			var leftsideconfig = document.getElementById("leftSideConfig");
			var playcontrolbuttons = document.getElementById("playControlButtons");
			var centrecontrols = document.getElementById("centreControls");
			
			if (episode.allowPlayerSelection !== false || episode.allowSaveSelection !== false) {
				leftsideconfig.style.display = "table"
				playcontrolbuttons.style.width = "50vw";
				//playcontrolbuttons.style.maxWidth = "100%";
				centrecontrols.style.minWidth = "420px";
			} else {
				leftsideconfig.style.display = "none"
				playcontrolbuttons.style.width = "100%";
				//playcontrolbuttons.style.maxWidth = "400px";
				centrecontrols.style.minWidth = "160px";
			}
			
			var charSelect = document.getElementById("characterSelect");
			var charSelectCell = document.getElementById("charSelectCell");
			
			if (episode.allowPlayerSelection !== false) {
				charSelect.style.display = "table-cell";
				charSelectCell.style.height = "40px";
			} else {
				charSelect.style.display = "none";
				charSelectCell.style.height = "0px";
			}

			// Set player selection
			var player1Label = document.getElementById("player1Label");
			var player2Label = document.getElementById("player2Label");
			player1Label.innerHTML = "";
			player2Label.innerHTML = "";
			var populatePlayerSelector = (function(containerObj, isPlayerTwo) {
				var selectObj = document.createElement("select");
				selectObj.style.height = "32px";
				var optionObj;
				if (isPlayerTwo) {
					// If this is the player2 dropdown, add a None option
					optionObj = document.createElement("option");
					optionObj.value = "0";
					optionObj.textContent = _("None");
					selectObj.appendChild(optionObj);
				}
				for (var idx = 0; idx < episode.allowedCharacters.length; idx++) {
					// Get character ID and character name
					var charId = episode.allowedCharacters[idx];
					var charName = episode.characterNames[charId-1];
					optionObj = document.createElement("option");
					optionObj.value = charId.toString();
					optionObj.textContent = charName;
					selectObj.appendChild(optionObj);
				}
				containerObj.appendChild(selectObj);
				return selectObj;
			});
			var butts = document.createElement("span");
			var butts2 = document.createElement("span");
			var player2Icon = document.getElementById("player2Icon");
			var player2Select = document.getElementById("player2Select");
			if (episode.allowTwoPlayer !== false) {
				player2Icon.style.display = "table-cell";
				player2Select.style.display = "table-cell";
			} else {
				player2Icon.style.display = "none";
				player2Select.style.display = "none";
			}
			/*if (episode.allowTwoPlayer !== false) {
				butts.appendChild(document.createTextNode(_("PlayerX", {x: 1})));
				player1Label.appendChild(butts);
			} else {
				butts.appendChild(document.createTextNode(_("Character")));
				player1Label.appendChild(butts);
			}*/
			player1Selector = populatePlayerSelector(player1Label, false);
			player1Label.style.display = "inline-block";
			if (episode.allowTwoPlayer !== false) {
				/*
				butts2.appendChild(document.createTextNode(_("PlayerX", {x: 2})));
				player2Label.appendChild(butts2);
				*/
				player2Selector = populatePlayerSelector(player2Label, true);
				player2Label.style.display = "inline-block";
			} else {
				player2Selector = null;
				player2Label.style.display = "none";
			}
			
			var saveSelect = document.getElementById("saveSelection");
			var saveSelectCell = document.getElementById("saveSelectCell");
			var savePaddingCell = document.getElementById("saveSelectPadding");
			
			if(episode.allowSaveSelection !== false) {
				saveSelectCell.style.display = "table-row"
				savePaddingCell.style.display = "none"
			} else {
				saveSelectCell.style.display = "none"
				savePaddingCell.style.display = "table-row"
				document.getElementById("currentSave").value = 1;
			}

			function onchange(idx) {
				document.getElementById("currentSave").value = this.options[this.selectedIndex].value;
				document.getElementById("deleteButton").style.display = this.options[this.selectedIndex].value == -1 ? "none" : "table-cell";
			}

			// Set save slot info
			Launcher.getSaveInfo(episode.directoryName, function(saveFileList) {
				var saveSlotContainer = document.getElementById("saveList");
				saveSlotContainer.onchange = onchange;

				while (saveSlotContainer.firstChild) {
					saveSlotContainer.remove(saveSlotContainer.firstChild);
				}

				firstEmptySaveSlot = 0;
				var lastHighestSlot = 0;
				
				updateEpisodeProgress(episode, saveFileList);

				for (var idx = 0; idx < saveFileList.length; idx = idx + 1) {
					var saveFile = saveFileList[idx];
					
					if (firstEmptySaveSlot === 0) {
						if (saveFile.id > lastHighestSlot + 1) {
							firstEmptySaveSlot = lastHighestSlot + 1
						}
						if (saveFile.id > lastHighestSlot) {
							lastHighestSlot = saveFile.id;
						}
					}
					var element = document.createElement("option");
					
					var progress;
					
					if (episode.maxProgress > 0) {
						if (episode.progressDisplay === "percent") {
							progress = Math.floor(100*saveFile.progress/parseFloat(episode.maxProgress)) + "%";
						} else {
							progress = getStarString(episode, true) + " " + saveFile.progress.toString() + "/" + episode.maxProgress.toString();
						} 
					}
					else if (episode.customProgress) {
						progress = getStarString(episode, true) + " " + saveFile.progress.toString();
					} else if (episode.stars > 0) {
						if (episode.progressDisplay === "percent") {
							progress = Math.floor(100*saveFile.starCount/parseFloat(episode.stars)) + "%";
						} else {
							progress = getStarString(episode, true) + " " + saveFile.starCount.toString() + "/" + episode.stars.toString();
						}
					} else {
						progress = getStarString(episode, true) + " " + saveFile.starCount.toString();
					}
					
					var savefilename = saveFile.savefilename;
					if (savefilename !== "") {
						savefilename += " - ";
					}
					
					element.textContent = (saveFile.id) + ") " + savefilename + progress;
					element.value = saveFile.id;
					element.setAttribute("data-save", saveFile.id)
					saveSlotContainer.appendChild(element);
				}
				if (lastHighestSlot < 32767) {
					var element = document.createElement("option");
					element.textContent = _("NewFile");
					element.value = -1;
					saveSlotContainer.appendChild(element);
					if (firstEmptySaveSlot == 0) {
						firstEmptySaveSlot = lastHighestSlot + 1;
					}
				}
				document.getElementById("currentSave").value = saveSlotContainer.firstChild.value;
				document.getElementById("deleteButton").style.display = saveSlotContainer.firstChild.value == -1 ? "none" : "table-cell";
			});
			
			var achievementsButton = document.getElementById("trophyIcon");			
			
			if (achievementIconsByEpisode[i] != null) {
					achievementsButton.style.minWidth = "24px";
					achievementsButton.style.width = "2vw";
					achievementsButton.style.padding = "5px";
			} else {	
					achievementsButton.style.minWidth = "0";
					achievementsButton.style.width = "0";
					achievementsButton.style.padding = "0";
			}
			// Check for updates
			Launcher.checkEpisodeUpdate(episode.directoryName, "launcher", "info.json", function(updateData){
				if (updateData) {
					if (isSecondVersionNewer(episode["current-version"], updateData["current-version"])) {
						var updateMsg = updateData["update-message"];
						if (updateMsg === undefined)
						{
							updateMsg = _("UpdateForEpisode", {episode: episode.title});
						}
						alert(updateMsg);
						if (updateData["download-url"]) {
							var aBomb = document.createElement("a");
							aBomb.setAttribute("href", updateData["download-url"]);
							aBomb.click();
						}
					}
				}
			});
			
			Launcher.setWindowHeader(episode.title);
		}

		function launchSMBXIGuess() {
			var episode = episodeData[parseInt(document.getElementById("currentEpisode").value)];
			Launcher.Autostart.useAutostart = true;
			if ((player1Selector === null) || (parseInt(player1Selector.value) == 0)) {
				if (episode.allowedCharacters !== null && episode.allowedCharacters.length > 0) {
					Launcher.Autostart.character1 = parseInt(episode.allowedCharacters[0]);
				} else {
					Launcher.Autostart.character1 = parseInt(1);
				}
			} else {
				Launcher.Autostart.character1 = parseInt(player1Selector.value);
			}
			if ((player2Selector === null) || (parseInt(player2Selector.value) == 0)) {
				Launcher.Autostart.singleplayer = true;
				Launcher.Autostart.character2 = parseInt(player1Selector.value);
			} else {
				Launcher.Autostart.singleplayer = false;
				Launcher.Autostart.character2 = parseInt(player2Selector.value);
			}
			Launcher.Autostart.saveSlot = parseInt(document.getElementById("currentSave").value);
			if (Launcher.Autostart.saveSlot == -1) {
				Launcher.Autostart.saveSlot = firstEmptySaveSlot;
			}
			Launcher.Autostart.wldPath = episode.wldpath;
			Launcher.runSMBX();
		}
		function populateEpisodeTemplate(episode, doc) {
			var starsField = doc.getElementsByClassName("_stars");
			var starsIcon = doc.getElementsByClassName("_starsIcon");
			var starsCount = doc.getElementsByClassName("_starsCount");
			var starsContainer = doc.getElementsByClassName("_starsContainer");
			var creditsField = doc.getElementsByClassName("_credits");
			var creditsContainer = doc.getElementsByClassName("_creditsContainer");
			var episodeIcon = doc.getElementsByClassName("_episodeIcon");
			var titleField = doc.getElementsByClassName("_episodeTitle");

			if (titleField) {
				Array.from(titleField).forEach(function(item) {
					item.textContent = episode.title;
				});
			}
			
			if (episodeIcon) {
				Array.from(episodeIcon).forEach(function(item) {
					var epIcon = doc.createElement("img");
					epIcon.setAttribute("src", getImagePath(episode, episode.episodeIcon, "default/icon.png"));
					item.appendChild(epIcon);
				});
			}
			
			var maxprog = 0
			if (episode.maxProgress > 0) {
				maxprog = episode.maxProgress;
			} else if (episode.stars) {
				maxprog = episode.stars;
			}
			
			if (starsIcon) {
				Array.from(starsIcon).forEach(function(item) {
					if (episode.starIcon || (!episode.collectible && !episode.collectibles)) {
						var starIcon = makeStarIcon(episode);
						item.appendChild(starIcon);
					} else {
						item.textContent = getStarString(episode, maxprog != 1);
					}
				});
			}
			
			if (starsCount) {	
				Array.from(starsCount).forEach(function(item) {
					if (maxprog > 0) {
						item.textContent = maxprog.toString();
					} else {
						item.textContent = "0";
					}
				});
			}
			
			if (starsField) {
				Array.from(starsField).forEach(function(item) {
					if (maxprog > 0) {
						if (episode.starIcon || (!episode.collectible && !episode.collectibles)) {
							var starIcon = makeStarIcon(episode);
							item.textContent = " " + maxprog.toString();
							item.insertBefore(starIcon, item.firstChild);
						} else {
							item.textContent = maxprog.toString() + " " + getStarString(episode, maxprog != 1);
						}
					} else {
						item.style.display = "none";
					}
				});
			}
			
			if (starsContainer && (maxprog == 0))
			{
				Array.from(starsContainer).forEach(function(item) {
					item.style.display = "none";
				});
			}
			
			if (creditsField) {
				Array.from(creditsField).forEach(function(item) {
					if (episode.credits) {
						item.innerHTML = "";
						var lines = episode.credits.trim().split("\n");
						var tableObj = doc.createElement("table");
						tableObj.className = "creditsTable";
						for (var i = 0; i < lines.length; i++) {
							var line = lines[i].trim();
							var trObj = doc.createElement("tr");
							var lineSections = line.split(":");
							var tdObj;
							if (lineSections.length == 2) {
								tdObj = doc.createElement("th");
								tdObj.textContent = lineSections[0].trim() + ": ";
								trObj.appendChild(tdObj);
								tdObj = doc.createElement("td");
								tdObj.textContent = lineSections[1].trim();
								trObj.appendChild(tdObj);
							}
							else
							{
								tdObj = doc.createElement("td");
								tdObj.textContent = line;
								tdObj.colSpan = "2";
								trObj.appendChild(tdObj);
							}
							tableObj.appendChild(trObj);
						}
						item.appendChild(tableObj);
					} else {
						item.style.display = "none";
					}
				});
			}
				
			if (creditsContainer && !episode.credits) 
			{	
				Array.from(creditsContainer).forEach(function(item) {
					item.style.display = "none";
				});
			}

		}
		function areWeSettingAKeyboard() {
			if (document.getElementById("useJoystick").checked) {
				return "joystick";
			} else {
				return "keyboard";
			}
		}
		function assignKeyCodes() {
			if (!document.getElementById("useJoystick").checked) {
				document.getElementById("gameConfigTab").querySelectorAll("input:not([type=button]):not([type=checkbox]):not([type=radio])").forEach(function(someInput) {
					if (someInput.value !== "unset") {
						someInput.value = keyboardMap[someInput.value];
					}
				});
			}
		}
		
		function populateControls() {
			var keyboardOrNot = areWeSettingAKeyboard();
			var setHidden;
			if (keyboardOrNot === "joystick") {
				setHidden = "none";
			} else {
				setHidden = "inline-block";
			}
			Array.from(document.getElementsByClassName("directionPad")).forEach(function(someDpad) {
				someDpad.style.display = setHidden;
			});
			Array.from(document.getElementsByClassName("buttonLabelContainer")).forEach(function(someLabel) {
				someLabel.title = someLabel.firstChild.innerHTML;
			});
			document.getElementById("gameConfigTab").querySelectorAll("input:not([type=button]):not([type=checkbox]):not([type=radio])").forEach(function(someInput) {
				someInput.value = Launcher.Controls[keyboardOrNot + someInput.id + document.querySelector('input[name="playerSelector"]:checked').value];
			});
			if (!document.getElementById("useJoystick").checked) {
				assignKeyCodes();
			}
		}
		
		var p1sel = document.getElementsByName("playerSelector")[0];
		var p2sel = document.getElementsByName("playerSelector")[1];
		
		p1sel.onchange = function() {
			document.getElementById("useJoystick").checked = (Launcher.Controls.controllerType1 === 1);
			document.getElementById("gameConfigTab").querySelectorAll("input:not([type=button]):not([type=checkbox]):not([type=radio])").forEach(function(someInput) {
				someInput.dataset.keyCode = Launcher.Controls["keyboard" + someInput.id + "1"];
				someInput.dataset.joyCode = Launcher.Controls["joystick" + someInput.id + "1"];
			});
			populateControls();
		}
		p2sel.onchange = function() {
			document.getElementById("useJoystick").checked = (Launcher.Controls.controllerType2 === 1);
			document.getElementById("gameConfigTab").querySelectorAll("input:not([type=button]):not([type=checkbox]):not([type=radio])").forEach(function(someInput) {
				someInput.dataset.keyCode = Launcher.Controls["keyboard" + someInput.id + "2"];
				someInput.dataset.joyCode = Launcher.Controls["joystick" + someInput.id + "2"];
			});
			populateControls();
		}
		
		function onControllerPress(buttonId, controllerName)
		{
			if (document.getElementById("gameConfigTab").style.display === "flex" && document.getElementById("useJoystick").checked) {
				document.activeElement.value = buttonId;
				document.activeElement.dataset.joyCode = buttonId;
			}
		}
		
		Launcher.ControllerButtonPress.connect(onControllerPress);
		
		function getImagePath(episode, name, def) {
			var path = window.location.pathname.split('data')[0]+"data/";
							
			if (name) {
				path += "worlds/" + episode.directoryName + "/launcher/" + name;
			} else {
				path += "launcher/" + def;
			}
			return path;
		}
		
		function getStarIconPath(episode) {
			return getImagePath(episode, episode.starIcon, "stars.png"); 
		}
		
		function makeStarIcon(episode) {
			var starIcon = document.createElement("img");
			starIcon.setAttribute("src", getStarIconPath(episode));
			starIcon.style.height = "16px";
			starIcon.style.verticalAlign = "middle";
			starIcon.style.imageRendering = "pixelated";
			
			return starIcon;
		}
		
		
			
		var episodeProgressList = {};
			
		function updateEpisodeProgress(episode, saveFileList) {
			if (episodeProgressList[episode.directoryName]) {
				var maxP = 0;
				if (episode.maxProgress > 0 || episode.customProgress) {
					maxP = episode.maxProgress;
				} else if (episode.stars) {
					maxP = episode.stars;
				}
				
				if (maxP > 0) {
					var maxS = null;
					for (var idx = 0; idx < saveFileList.length; idx = idx + 1) {
						var saveF = saveFileList[idx];
						if (episode.maxProgress > 0) {
							if (maxS === null || maxS < saveF.progress) {
								maxS = saveF.progress;
							}
						} else {
							if (maxS === null || maxS < saveF.starCount) {
								maxS = saveF.starCount;
							}
						}
					}
					
					if (maxS === null) {
						maxS = 0;
					}
					
					var starT;
					if (episode.progressDisplay === "percent") {
						starT = Math.floor(100*maxS/parseFloat(maxP)) + "%";
					} else {
						starT = maxS + "/" + maxP.toString();
					}
				}
				episodeProgressList[episode.directoryName].text.textContent = starT;
				
				if (episode.progressDisplay === "percent") {
					episodeProgressList[episode.directoryName].bar.style.width = starT;
				}
			}
		}
		
		var iframeOnLoadHandler = null;
		var player1Selector = null;
		var player2Selector = null;
		var ulObj = document.createElement("ul");
		ulObj.id = "episodeUl";
		function populateEpisodeData(episodeData, i) {
			var episode = episodeData[i];
			var liObj, liSpan1, liSpan2, iconImage, lineBreak, starSpan, maxStarCount;

			//Let's get those achievements set up...
			getLocalFile("../worlds/" + episode.directoryName + "/achievements/").then(function(response) {
				var iniFileList = listLocalFiles(response, 'ach-', '\\.ini', true);
				var achievementIDs = {};
				var maxID = 0;
				for (var j = 0; j < iniFileList.length; j++) {
					var id = iniFileList[j].match(/ach-(\d+).ini/)[1];
					if (id != null) {
						achievementIDs[id] = true;
						id = Number(id);
						if (id > maxID) {
							maxID = id;
						}
					}
				}
				
				var iniFileData = [];
				var iniFileDataPromise = Promise.all(iniFileList.map(function(iniFilename) {
					return(getLocalFile("../worlds/" + episode.directoryName + "/achievements/" + iniFilename).catch(function(reason) {
						return null;
					}).then(function(response) {
						return parseIniString(response);
					}));
				}));
				var progressFilePromise = getProgressJson("../worlds/" + episode.directoryName + "/progress.json");

				Promise.all([iniFileDataPromise, progressFilePromise]).then(function (response) {
					var iniFileData = response[0].filter(v => v !== null );
					var progressFile = response[1];
					if (progressFile != null) {
						progressFile = JSON.parse(progressFile);
					}
					addToAchievementCenter(progressFile, iniFileData, episode, i, maxID, achievementIDs);
				});
			});
			
			Launcher.getSaveInfo(episode.directoryName, function(saveFileList) {
				if (episode["hidden"] !== true) {
					liObj = document.createElement("li");
					liObj.dataset.identifier = i;
					liSpan1 = document.createElement("span");
					iconImage = document.createElement("img");
					if (episode.episodeIcon) {
						iconImage.setAttribute("src", "../worlds/" + episode.directoryName + "/launcher/" + episode.episodeIcon);
					} else {
						iconImage.setAttribute("src", "default/icon.png");
					}
					iconImage.style.imageRendering = "pixelated";
					iconImage.style.width = "64px";
					iconImage.style.height = "64px";
					liSpan1.appendChild(iconImage);
					liSpan1.setAttribute("class", "episodeIcons");
					liSpan2 = document.createElement("span");
					liSpan2.textContent = episode.title;
					liSpan2.setAttribute("class", "episodeNames");
					
					var maxProg = 0;
					if (episode.maxProgress > 0 || episode.customProgress) {
						maxProg = episode.maxProgress;
					} else if (episode.stars) {
						maxProg = episode.stars;
					}
					if (maxProg > 0) {
						lineBreak = document.createElement("br");
						liSpan2.appendChild(lineBreak);
						liSpan2.appendChild(lineBreak.cloneNode());
						
						var maxStars = null;
						for (var idx = 0; idx < saveFileList.length; idx = idx + 1) {
							var saveFile = saveFileList[idx];
							if (episode.maxProgress > 0) {
								if (maxStars === null || maxStars < saveFile.progress) {
									maxStars = saveFile.progress;
								}
							} else {
								if (maxStars === null || maxStars < saveFile.starCount) {
									maxStars = saveFile.starCount;
								}
							}
						}
						
						if (maxStars === null) {
							maxStars = 0;
						}
						
						starSpan = document.createElement("span");
						starSpan.setAttribute("class", "theLiteralWordStars");
						
						if (episode.progressDisplay !== "percent") {
							if (episode.starIcon || (!episode.collectible && !episode.collectibles)) {
								var starIcon = makeStarIcon(episode)
								starSpan.textContent = " ";
								starSpan.insertBefore(starIcon, starSpan.firstChild);
							} else {
								starSpan.textContent = getStarString(episode, true) + " ";
							}
							liSpan2.appendChild(starSpan);
						}
						
						var starText;
						if (episode.progressDisplay === "percent") {
							starText = Math.floor(100*maxStars/parseFloat(maxProg)) + "%";
						} else {
							starText = maxStars + "/" + maxProg.toString();
						}
						
						
						if (episode.progressDisplay === "percent") {
							maxStarCount = document.createTextNode(starText);
							var percentBg = document.createElement("div");
							percentBg.setAttribute("class", "percentProgressBG");
							var percentProg = document.createElement("div");
							percentProg.setAttribute("class", "percentProgress");
							percentProg.style.width = starText;
							percentBg.appendChild(percentProg);
							var percentText = document.createElement("div");
							percentText.setAttribute("class", "percentProgressText");
							percentText.appendChild(maxStarCount);
							percentBg.appendChild(percentText);
							liSpan2.appendChild(percentBg);
							episodeProgressList[episode.directoryName] = {text:maxStarCount, bar:percentProg};
						} else {
							maxStarCount = document.createTextNode(starText);
							liSpan2.appendChild(maxStarCount);
							episodeProgressList[episode.directoryName] = {text:maxStarCount};
						}
					}
					liObj.appendChild(liSpan1);
					liObj.appendChild(liSpan2);
					liObj.onclick = function () {
						document.getElementById("currentEpisode").value = this.dataset.identifier;
						selectEpisodeById(this.dataset.identifier);
						document.getElementById("iframer").style.display = "block";
						document.getElementById("achievementCenter").style.display = "none";
						document.getElementById("gameConfigTab").style.display = "none";
						document.getElementById("currentSave").value = 1;
					};
					ulObj.appendChild(liObj);
				}
			});
		}

		for (var i = 0; i < episodeData.length; i = i + 1) {
			populateEpisodeData(episodeData, i);
		}
		
		document.getElementById("episodeInfo").appendChild(ulObj);
		selectEpisodeById(document.getElementById("currentEpisode").value);
		
		if(!Launcher.hasInternetAccess) {
			document.getElementById("internetBar").style.display = "block";
		}
		
		if(Launcher.hasUpdate) {
			document.getElementById("updateBar").style.display = "block";
			document.getElementById("updateBar").onclick = function() { Launcher.openUpdateWindow(); };
			if(Launcher.updateLevel <= 5) {
				document.getElementById("updateBar").innerHTML = _("MajorUpdate", {version: Launcher.updateVersionName});
			} else if(Launcher.updateLevel >= 6) {
				document.getElementById("updateBar").innerHTML = _("MinorUpdate", {version: Launcher.updateVersionName});
			}
		}
		
		if (localStorage.getItem("left") == "true") {
			document.getElementById("leftColumn").style.display = "block";
		}
		if (localStorage.getItem("right") == "true") {
			document.getElementById("rightColumn").style.display = "block";
		}
		
		document.getElementById("playButton").onclick = function () {
			launchSMBXIGuess();
		};
		/*
		document.getElementById("classicEditorButton").onclick = function () {
			Launcher.runSMBXEditor();
		}
		*/
		document.getElementById("newEditorButton").onclick = function () {
			Launcher.runPGEEditor();
		};
		document.getElementById("deleteSaveSlot").onclick = function() {
			var episode = episodeData[parseInt(document.getElementById("currentEpisode").value)];
			var slot = parseInt(document.getElementById("currentSave").value);
			Launcher.deleteSaveSlot(episode.directoryName, slot);
			selectEpisodeById(parseInt(document.getElementById("currentEpisode").value));
		};
		
		document.getElementById("leftIcon").onclick = function () {
			var col = document.getElementById("leftColumn");
			onOff(col, "left");
			
			//In-out animations
			var animspd = 0.05;
			if (col.style.display === "block") {
				var t = 1;
				col.style.marginLeft = (-col.clientWidth)+"px";
				var anim = setInterval(function() { 
										if (t <= 0) {
											col.style.marginLeft = "0"; 
											clearInterval(anim);
										} else {
											col.style.marginLeft = (-t*col.clientWidth)+"px";
											t-=animspd;
										}
									}, 5);
			} else {
				col.style.display = "block";
				var t = 0;
				var anim = setInterval(function() { 
									if (t >= 1) {
										col.style.marginLeft = "0"; 
										col.style.display = "none";
										clearInterval(anim);
									} else {
										col.style.marginLeft = (-t*col.clientWidth)+"px";
										t+=animspd;
									}
								}, 5);
			}
		};
		document.getElementById("rightIcon").onclick = function () {
			var col = document.getElementById("rightColumn");
			onOff(col, "right");
			
			//In-out animations
			var animspd = 0.05;
			if (col.style.display === "block") {
				col.style.marginRight = (-col.clientWidth)+"px"; 
				var t = 1;
				var anim = setInterval(function() { 
										if (t <= 0) {
											col.style.marginRight = "0"; 
											clearInterval(anim);
										} else {
											col.style.marginRight = (-t*col.clientWidth)+"px";
											t-=animspd;
										}
									}, 5);
			} else {
				col.style.display = "block";
				var t = 0;
				var anim = setInterval(function() { 
									if (t >= 1) {
										col.style.marginRight = "0"; 
										col.style.display = "none";
										clearInterval(anim);
									} else {
										col.style.marginRight = (-t*col.clientWidth)+"px";
										t+=animspd;
									}
								}, 5);
			}
		};
		/*document.getElementById("bugIcon").onclick = function () {
			var tempLink = document.createElement("a");
			tempLink.href = "http://codehaus.moe/";
			tempLink.click();
		};*/

		var mailform = "Please\xa0use\xa0the\xa0form\xa0below\xa0to\xa0describe\xa0the\xa0issue\xa0you\xa0have\xa0encountered.\xa0Please\xa0include\xa0any\xa0helpful\xa0screenshots,\xa0including\xa0screenshots\xa0of\xa0any\xa0error\xa0messages\xa0or\xa0stack\xa0traces\xa0you\xa0encountered.\n\nWhat\xa0action\xa0did\xa0you\xa0perform\xa0that\xa0lead\xa0to\xa0the\xa0bug\xa0you\xa0have\xa0encountered?\n\n\nWhat\xa0behaviour\xa0did\xa0you\xa0encounter?\n\n\nWhat\xa0did\xa0you\xa0expect\xa0to\xa0encounter\xa0instead?\n\n\nPlease\xa0put\xa0further\xa0information\xa0that\xa0might\xa0be\xa0helpful\xa0for\xa0us\xa0to\xa0know\xa0here,\xa0such\xa0as\xa0operating\xa0system\xa0or\xa0hardware\xa0specifications.\n\n\n"

		//Consider expanding this with hardware specs in the future.
		
		document.getElementById("openIcon").onclick = function () {
			
			Launcher.openLevelDialog();
		};
		
		document.getElementById("openFile").change = function(path) {
		};
		
		document.getElementById("bugReportIcon").value = mailform;

		document.getElementById("trophyIcon").onclick = function () {
			toggleOther("achievementCenter");
			updateAchievementCenterContents(document.getElementById("currentEpisode").value);
		};
		
		document.getElementById("homeIcon").onclick = function () {
			disableOther("achievementCenter");
			disableOther("gameConfigTab");
		};
		/*document.getElementById("saveIcon").onclick = function () {
			manageBottomPanel("saveButtonsBox");
		};*/
		/*document.getElementById("playerIcon").onclick = function () {
			manageBottomPanel("playerButtons");
		};*/
		/*document.getElementById("homeIcon").onclick = function () {
			manageBottomPanel("playButtons");
		};*/
		document.getElementById("controllerIcon").onclick = function () {
			toggleOther("gameConfigTab");
		};
		document.getElementById("filterEpisodes").onkeyup = function () {
			var filter, ul, li, i;
			filter = this.value.toUpperCase();
			ul = document.getElementById("episodeUl");
			li = ul.getElementsByTagName("li");
			
			var first = true;
			
			for (i = 0; i < li.length; i = i + 1) {
				if (li[i].textContent.toUpperCase().indexOf(filter) > -1) {
					li[i].style.display = "";
					if (first) {
						li[i].style.borderTop = "none";
						first = false;
					} else {
						li[i].style.borderTop = "1px solid black";
					}
				} else {
					li[i].style.display = "none";
				}
			}
		};
		document.getElementById("gameConfigTab").querySelectorAll("input:not([type=button]):not([type=checkbox])").forEach(function(someInput) {
			someInput.onkeyup = function (event) {
				if (!document.getElementById("useJoystick").checked) {
					this.value = keyboardMap[event.keyCode];
					this.dataset.keyCode = event.keyCode;
				}
			}
		});
		var controlsSavedTimeout;
		document.getElementById("saveControls").onclick = function () {
			Launcher.Controls["controllerType" + document.querySelector('input[name="playerSelector"]:checked').value] = Number(document.getElementById("useJoystick").checked);
			var playerNumber = document.querySelector('input[name="playerSelector"]:checked').value;
			document.getElementById("gameConfigTab").querySelectorAll("input:not([type=button]):not([type=checkbox]):not([type=radio])").forEach(function(someInput) {
				//if (someInput.value) {
					Launcher.Controls["joystick" + someInput.id + playerNumber] = someInput.dataset.joyCode;
					Launcher.Controls["keyboard" + someInput.id + playerNumber] = someInput.dataset.keyCode;
				//}
			});
			Launcher.Controls.write();
			var controlsSaved = document.getElementById("controlsSaved")
			controlsSaved.style.display = "block";
			clearTimeout(controlsSavedTimeout);
			controlsSavedTimeout = setTimeout(function() {
				controlsSaved.style.display = "none";
			}, 2000);
		
			//alert(_("ControlsSaved"));
		};
		document.getElementById("otherOptions").querySelectorAll("input:not([type=button])").forEach(function(someClickerThing) {
			someClickerThing.onclick = function() {
				populateControls();
			}
		});
		if (Launcher.Controls.controllerType1 === 1) {
			document.getElementById("useJoystick").checked = "checked";
		}
		Launcher.Controls.read(function(success){
			if (!success) {
				var playerNumber = [1, 2]
				var keyDefaults = [{keyName: "Up", keyValue: 38}, {keyName: "Down", keyValue: 40}, {keyName: "Left", keyValue: 37}, {keyName: "Right", keyValue: 39}, {keyName: "Run", keyValue: 88, joyValue: 2}, {keyName: "Jump", keyValue: 90, joyValue: 0}, {keyName: "Drop", keyValue: 16, joyValue: 6}, {keyName: "Pause", keyValue: 27, joyValue: 7}, {keyName: "AltJump", keyValue: 65, joyValue: 1}, {keyName: "AltRun", keyValue: 83, joyValue: 3}]
				playerNumber.forEach(function(somePlayer) {
					keyDefaults.forEach(function(someKeyDefault) {
						if (someKeyDefault.joyValue) {
							Launcher.Controls["joystick" + someKeyDefault.keyName + somePlayer] = someKeyDefault.joyValue;
						}
						Launcher.Controls["keyboard" + someKeyDefault.keyName + somePlayer] = someKeyDefault.keyValue;
						console.log("keyboard" + someKeyDefault.keyName + somePlayer + "  is now   " + someKeyDefault.keyValue);
					});
				});
				Launcher.Controls.write();
			}
		});
		populateControls();
		//Handle right-hand-side panel RSS Content
		showPosts();
	});
	
	launcherLoaded = true;
};
