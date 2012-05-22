/**
 * UI infrastructure code and utility code for the gaia email app.
 **/

var mozL10n = document.mozL10n;

function dieOnFatalError(msg) {
  console.error('FATAL:', msg);
  throw new Error(msg);
}

var fldNodes, msgNodes, cmpNodes, supNodes, tngNodes;
function processTemplNodes(prefix) {
  var holder = document.getElementById('templ-' + prefix),
      nodes = {},
      node = holder.firstElementChild,
      reInvariant = new RegExp('^' + prefix + '-');
  while (node) {
    var classes = node.classList, found = false;
    for (var i = 0; i < classes.length; i++) {
      if (reInvariant.test(classes[i])) {
        var name = classes[i].substring(prefix.length + 1);
        nodes[name] = node;
        found = true;
        break;
      }
    }
    if (!found) {
      console.warn('Bad template node for prefix "' + prefix +
                   '" for node with classes:', classes);
    }

    node = node.nextElementSibling;
  }

  return nodes;
}
function populateTemplateNodes() {
  fldNodes = processTemplNodes('fld');
  msgNodes = processTemplNodes('msg');
  cmpNodes = processTemplNodes('cmp');
  supNodes = processTemplNodes('sup');
  tngNodes = processTemplNodes('tng');
}

/**
 * Add an event listener on a container that, when an event is encounted on
 * a descendent, walks up the tree to find the immediate child of the container
 * and tells us what the click was on.
 */
function bindContainerHandler(containerNode, eventName, func) {
  containerNode.addEventListener(eventName, function(event) {
    var node = event.target;
    while (node && node.parentNode !== containerNode) {
      node = node.parentNode;
    }
    func(node, event);
  }, false);
}

/**
 * Fairly simple card abstraction with support for simple horizontal animated
 * transitions.  We are cribbing from deuxdrop's mobile UI's cards.js
 * implementation created jrburke.
 */
var Cards = {
  /**
   * @dictof[
   *   @key[name String]
   *   @value[@dict[
   *     @key[name String]{
   *       The name of the card, which should also be the name of the css class
   *       used for the card when 'card-' is prepended.
   *     }
   *     @key[modes @dictof[
   *       @key[modeName String]
   *       @value[modeDef @dict[
   *         @key[tray Boolean]{
   *           Should this card be displayed as a tray that leaves the edge of
   *           the adjacent card visible?  (The width of the edge being a
   *           value consistent across all cards.)
   *         }
   *       ]
   *     ]]
   *     @key[constructor Function]{
   *       The constructor to use to create an instance of the card.
   *     }
   *   ]]
   * ]
   */
  _cardDefs: {},

  /**
   * @listof[@typedef[CardInstance @dict[
   *   @key[domNode]{
   *   }
   *   @key[cardDef]
   *   @key[modeDef]
   *   @key[left Number]{
   *     Left offset of the card in #cards.
   *   }
   *   @key[cardImpl]{
   *     The result of calling the card's constructor.
   *   }
   * ]]]{
   *   Existing cards, left-to-right, new cards getting pushed onto the right.
   * }
   */
  _cardStack: [],
  _activeCardIndex: null,

  _containerNode: null,
  _cardsNode: null,
  /**
   * DOM template nodes for the cards.
   */
  _templateNodes: null,

  /**
   * The DOM nodes that should be removed from their parent when our current
   * transition ends.
   */
  _animatingDeadDomNodes: [],

  /**
   * Is a tray card visible, suggesting that we need to intercept clicks in the
   * tray region so that we can transition back to the thing visible because of
   * the tray and avoid the click triggering that card's logic.
   */
  _trayActive: false,

  TRAY_GUTTER_WIDTH: 80,

  /**
   * Initialize and bind ourselves to the DOM which should now be fully loaded.
   */
  _init: function() {
    this._containerNode = document.getElementById('cardContainer');
    if (window.innerWidth > 360)
      this._containerNode.style.width = '360px';
    if (window.innerHeight > 480)
      this._containerNode.style.height = '480px';
    this._cardsNode = document.getElementById('cards');
    this._templateNodes = processTemplNodes('card');

    this._containerNode.addEventListener('click',
                                         this._onMaybeTrayIntercept.bind(this),
                                         true);

    this._adjustCardSizes();
    window.addEventListener('resize', this._adjustCardSizes.bind(this), false);

    // XXX be more platform detecty. or just add more events. unless the
    // prefixes are already gone with webkit and opera?
    this._cardsNode.addEventListener('transitionend',
                                     this._onTransitionEnd.bind(this),
                                     false);
  },

  /**
   * If the tray is active and a click happens in the tray area, transition
   * back to the visible thing (which must be to our right currently.)
   */
  _onMaybeTrayIntercept: function(event) {
    if (this._trayActive &&
        (event.clientX >
         this._containerNode.offsetWidth - this.TRAY_GUTTER_WIDTH)) {
      event.stopPropagation();
      this.moveToCard(this._activeCardIndex + 1);
    }
  },

  _adjustCardSizes: function() {
    var cardWidth = Math.min(360, window.innerWidth), //this._containerNode.offsetWidth,
        cardHeight = Math.min(480, window.innerHeight), //this._containerNode.offsetHeight,
        totalWidth = 0;

    for (var i = 0; i < this._cardStack.length; i++) {
      var cardInst = this._cardStack[i];
      var targetWidth = cardWidth;
      if (cardInst.modeDef.tray)
        targetWidth -= this.TRAY_GUTTER_WIDTH;
      cardInst.domNode.style.width = targetWidth + 'px';
      cardInst.domNode.style.height = cardHeight + 'px';

      cardInst.left = totalWidth;
      totalWidth += targetWidth;
    }
    this._cardsNode.style.width = totalWidth + 'px';
    this._cardsNode.style.height = cardHeight + 'px';
  },

  defineCard: function(cardDef) {
    if (!cardDef.name)
      throw new Error('The card type needs a name');
    if (this._cardDefs.hasOwnProperty(cardDef.name))
      throw new Error('Duplicate card name: ' + cardDef.name);
    this._cardDefs[cardDef.name] = cardDef;

    // normalize the modes
    for (var modeName in cardDef.modes) {
      var mode = cardDef.modes[modeName];
      if (!mode.hasOwnProperty('tray'))
        mode.tray = false;
      mode.name = modeName;
    }
  },

  /**
   * Push a card onto the card-stack.
   *
   * @args[
   *   @param[type]
   *   @param[mode String]{
   *   }
   *   @param[showMethod @oneof[
   *     @case['animate']{
   *       Perform an animated scrolling transition.
   *     }
   *     @case['immediate']{
   *       Immediately warp to the card without animation.
   *     }
   *     @case['none']{
   *       Don't touch the view at all.
   *     }
   *   ]]
   *   @param[args Object]{
   *     An arguments object to provide to the card's constructor when
   *     instantiating.
   *   }
   * ]
   */
  pushCard: function(type, mode, showMethod, args) {
    var cardDef = this._cardDefs[type];
    if (!cardDef)
      throw new Error('No such card def type: ' + type);
    var modeDef = cardDef.modes[mode];
    if (!modeDef)
      throw new Error('No such card mode: ' + mode);

    var domNode = this._templateNodes[type].cloneNode(true);

    var cardImpl = new cardDef.constructor(domNode, mode, args);
    var cardInst = {
      domNode: domNode,
      cardDef: cardDef,
      modeDef: modeDef,
      cardImpl: cardImpl,
    };
    this._cardStack.push(cardInst);
    this._cardsNode.appendChild(domNode);
    this._adjustCardSizes();

    // XXX for now, always animate... (Need to disable 'left' as an animatable
    // property, set left, and then re-enable.  Need to trigger one or more
    // reflows for that to work right.)
    if (showMethod !== 'none') {
      // Position the card so its leftmost edge lines up with the left of the
      // display.  This works with trays on the left side, but not the right
      // side.
      this._cardsNode.style.left = (-cardInst.left) + 'px';
      this._activeCardIndex = this._cardStack.length - 1;
    }
  },

  _findCardInstInStack: function(type, mode) {
    for (var i = 0; i < this._cardStack.length; i++) {
      var cardInst = this._cardStack[i];
      if (cardInst.cardDef.name === type &&
          cardInst.modeDef.name === mode) {
        return i;
      }
    }
    throw new Error('Unable to find card with type: ' + type + ' mode: ' +
                    mode);
  },

  moveToCard: function(maybeType, mode) {
    if (typeof(type) === 'string')
      this._activeCardIndex = this._findCardInstInStack(maybeType, mode);
    else // number, it's the index to move to
      this._activeCardIndex = maybeType;

    var cardInst = this._cardStack[this._activeCardIndex];
    this._cardsNode.style.left = (-cardInst.left) + 'px';

    this._trayActive = cardInst.modeDef.tray;
  },

  /**
   * Remove the card identified by its DOM node and all the cards to its right.
   * Pass null to remove all of the cards!
   *
   * @args[
   *   @param[cardDomNode]{
   *     The DOM node that is the first card to remove; all of the cards to its
   *     right will also be removed.  If null is passed it is understood you
   *     want to remove all cards.
   *   }
   *   @param[showMethod @oneof[
   *     @case['animate']{
   *       Perform an animated scrolling transition.
   *     }
   *     @case['immediate']{
   *       Immediately warp to the card without animation.
   *     }
   *     @case['none']{
   *       Remove the nodes immediately, don't do anything about the view
   *       position.  You only want to do this if you are going to push one
   *       or more cards and the last card will use a transition of 'immediate'.
   *     }
   *   ]]
   * ]
   */
  removeCardAndSuccessors: function(cardDomNode, showMethod) {
    if (!this._cardStack.length)
      return;

    var firstIndex, iCard, cardInst;
    if (cardDomNode == null) {
      firstIndex = 0;
    }
    else {
      for (iCard = this._cardStack.length - 1; iCard >= 0; iCard--) {
        cardInst = this._cardStack[iCard];
        if (cardInst.domNode === cardDomNode) {
          firstIndex = iCard;
          break;
        }
      }
      if (firstIndex === undefined)
        throw new Error('No card represented by that DOM node');
    }

    var deadCardInsts = this._cardStack.splice(
                          firstIndex, this._cardStack.length - firstIndex);
    for (iCard = 0; iCard < deadCardInsts.length; iCard++) {
      cardInst = deadCardInsts[iCard];
      try {
        cardInst.cardImpl.die();
      }
      catch (ex) {
        console.warn('Problem cleaning up card:', ex, '\n', ex.stack);
      }
      switch (showMethod) {
        case 'animate':
        case 'immediate': // XXX handle properly
          this._animatingDeadDomNodes.push(cardInst.domNode);
          break;
        case 'none':
          cardInst.domNode.parentNode.removeChild(cardInst.domNode);
          break;
      }
    }
    if (showMethod !== 'none') {
      var targetLeft = '0px';
      if (this._cardStack.length)
        targetLeft = (-this._cardStack[this._cardStack.length - 1].left) +
                       'px';
      this._cardsNode.style.left = targetLeft;
    }
  },

  _onTransitionEnd: function(event) {
    if (this._animatingDeadDomNodes.length) {
      this._animatingDeadDomNodes.forEach(function(domNode) {
        if (domNode.parentNode)
          domNode.parentNode.removeChild(domNode);
      });
    }
  },

  /**
   * If there are any cards on the deck right now, log an error and clear them
   * all out.  Our caller is strongly asserting that there should be no cards
   * and the presence of any indicates a bug.
   */
  assertNoCards: function() {
    if (this._cardStack.length)
      throw new Error('There are ' + this._cardStack.length + ' cards but' +
                      ' there should be ZERO');
  },
};

////////////////////////////////////////////////////////////////////////////////
// Pretty date logic; copied from the SMS app.
// Based on Resig's pretty date

function prettyDate(time) {

  switch (time.constructor) {
    case String:
      time = parseInt(time);
      break;
    case Date:
      time = time.getTime();
      break;
  }

  var diff = (Date.now() - time) / 1000;
  var day_diff = Math.floor(diff / 86400);

  if (isNaN(day_diff))
    return '(incorrect date)';

  if (day_diff < 0 || diff < 0) {
    // future time
    return (new Date(time)).toLocaleFormat('%x %R');
  }

  return day_diff == 0 && (
    diff < 60 && 'Just Now' ||
    diff < 120 && '1 Minute Ago' ||
    diff < 3600 && Math.floor(diff / 60) + ' Minutes Ago' ||
    diff < 7200 && '1 Hour Ago' ||
    diff < 86400 && Math.floor(diff / 3600) + ' Hours Ago') ||
    day_diff == 1 && 'Yesterday' ||
    day_diff < 7 && (new Date(time)).toLocaleFormat('%A') ||
    (new Date(time)).toLocaleFormat('%x');
}

(function() {
  var updatePrettyDate = function updatePrettyDate() {
    var labels = document.querySelectorAll('[data-time]');
    var i = labels.length;
    while (i--) {
      labels[i].textContent = prettyDate(labels[i].dataset.time);
    }
  };
  var timer = setInterval(updatePrettyDate, 60 * 1000);

  window.addEventListener('message', function visibleAppUpdatePrettyDate(evt) {
    var data = evt.data;
    if (data.message !== 'visibilitychange')
      return;
    clearTimeout(timer);
    if (!data.hidden) {
      updatePrettyDate();
      timer = setInterval(updatePrettyDate, 60 * 1000);
    }
  });
})();

////////////////////////////////////////////////////////////////////////////////
