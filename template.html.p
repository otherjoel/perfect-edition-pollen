<!DOCTYPE html>
<html lang="en">
<!--

Don't worry, spiders,
I keep house
casually.

Kobayashi Issa

-->
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1.0, minimum-scale=1.0, user-scalable=0.0" />
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">

  <!-- OpenGraph metadata -->
  <meta property="og:title" content="{{ title }}" />
  <meta property="og:site_name" content="{{ title }} by {{ author }}" />
  <meta property="og:type" content="book" />
  <meta property="og:book:author" content="{{ author }}" />
  <meta property="og:image" content="{{ home_url }}{{ cover_image }}" />
  <meta property="og:description" content="{{ description }}" />
  <meta property="og:url" content="{{ home_url }}" />

  {% if use_twitter_card %}
  <!-- Twitter Card metadata -->
  <meta name="twitter:card" content="summary" />
  <meta name="twitter:site" content="{{ twitter_username }}" />
  <meta name="twitter:title" content="{{ title }} by {{ author }}" />
  <meta name="twitter:description" content="{{ description }}" />
  <meta name="twitter:image" content="{{ home_url }}{{ cover_image }}" />
  {% endif %}

  <!-- JSON-LD metadata -->
  <script type="application/ld+json">
      {
          "@context": "http://schema.org",
          "@type": "Book",
          "name": "{{ title }}",
          "author": "{{ author }}",
          "description": "{{ description }}",
          "url": "{{ home_url }}"
      }
  </script>


  <meta name="generator" content="These human fingers" />

  <link href="css/web.css" type="text/css" rel="stylesheet" />

  <title>◊(select-from-metas 'title metas)</title>
  <script>

  // https://github.com/iamdustan/smoothscroll/blob/master/src/smoothscroll.js
  function smoothScroll(x) {
    var startTime = performance.now();
    var startX = document.body.scrollLeft;
    var startY = 0;

    // scroll
    smoothScrollStep({
      startTime: startTime,
      startX: startX || 0,
      startY: 0,
      x: x || 0,
      y: 0
    });
  }

  function ease(k) {
    //return 0.5 * (1 - Math.cos(Math.PI * k));
    //return 1-(--k)*k*k*k;
    //return k*k*k*k*k;
    return (-Math.pow( 2, -10 * k ) + 1 );
  }

  const SCROLL_TIME = 200;

  function smoothScrollStep(context) {
    let time = performance.now()
    let value;
    let currentX;
    let elapsed = (time - context.startTime) / SCROLL_TIME;

    // avoid elapsed times higher than one
    elapsed = elapsed > 1 ? 1 : elapsed;

    // apply easing to elapsed time
    value = ease(elapsed);

    currentX = context.startX + (context.x - context.startX) * value;

    // document.body.scrollTo(currentX, 0);
    document.body.scrollLeft = currentX;

    // keep scrolling if we have not reached our destination
    // this was > 1.0 and that wasn't working for some reason
    if (Math.abs(currentX - context.x) > 2.0) {
      requestAnimationFrame(smoothScrollStep.bind(window, context));
    } else {
      // other side of possible mobile optimizaton thing
      // document.body.style.backgroundColor = realColor;
    }
  }

  // snap scroll helper
  // inspired by:
  // https://github.com/jpamental/moby-dick/pull/5/commits/ec022061684ae4c233fba047fb341b41deeead6c

  function setupShadowPages() {
    // is this guaranteed to execute AFTER column layout occurs?
    // currently: i do not know

    let pageCount = Math.floor( bookElement.scrollWidth / window.innerWidth );

    pageCount += 10; // uhhh :)

    document.documentElement.style.setProperty("--page-count", pageCount);

    let shadowPageContainer = document.querySelector("div.shadow-page-container");

    for (let i = 0; i < pageCount; i++) {
      let shadowPage = document.createElement("div");
      shadowPage.innerHTML = " ";
      shadowPage.className = "shadow-page";
      shadowPageContainer.appendChild(shadowPage);
    }
  }

  function getComputed(propertyName) {
    return Number( getComputedStyle(bookElement)
                  .getPropertyValue(propertyName)
                  .replace("px", "") );
  }

  function getRect(element) {
    // Terrible hack for Firefox, which treats getBoundingClientRect as an
    // inner dimension for some unknown reason.
    let rects = element.getClientRects();
    return rects[rects.length - 1]
  }

  function turnPageForward() {
    turnPage(1);
  }

  function turnPageBack() {
    turnPage(-1);
  }

  function turnPage(turnDirection) {

    let currentLeftOffset = document.body.scrollLeft;

    let columnWidth = getComputed("column-width");
    let columnGap = getComputed("column-gap");
    let columnTotal = columnWidth + columnGap;

    // this was previously Math.floor which was causing problems when
    // paging backwards

    let closestPageNumber = Math.round( currentLeftOffset / columnTotal ) + turnDirection;

    writePageNumber(closestPageNumber);

    let closestPageEdge = closestPageNumber * columnTotal;

    // aha, but what if we are already AT that page?
    // 8.0 pixels is a bit of a "magic number"...
    if ( Math.abs( closestPageEdge - currentLeftOffset) < 8.0 ) {
      closestPageEdge += columnTotal * turnDirection;
      writePageNumber( closestPageNumber + 1 ); // hacky
    }

    // there's got to be a better way to do this...
    if ( (turnDirection > 0) &&
         ( getRect(endElement).x < window.innerWidth )
       ) {

      return;
    }

    // if we're turning a page, we are navigating away from a chapter title,
    // so we want to clear this out
    window.location.hash = "";

    smoothScroll(closestPageEdge);
  }

  function turnToPage(pageNumber) {
    let columnWidth = getComputed("column-width");
    let columnGap = getComputed("column-gap");
    let columnTotal = columnWidth + columnGap;

    let pageEdge = pageNumber * columnTotal;

    writePageNumber(pageNumber);

    // the cute tiny bookmark
    let bookmarkElement = document.querySelector("div.bookmark");
    bookmarkElement.style.display = "block";
    // bookmarkElement.style.top = `0px`;
    bookmarkElement.style.left = `${pageEdge + columnWidth / 2.0}px`;
    console.log(bookmarkElement.style.left);

    document.body.scrollLeft = pageEdge;
  }

  function turnToAnchor(anchor) {
    let editedAnchor = "chapter_" + anchor.replace( "#", "" );

    let anchoredHeading = Array.from( document.querySelectorAll("h2") )
                               .find( heading => {
                                  return heading.getAttribute("id") == editedAnchor;
                                } );

    anchoredHeading.scrollIntoView();

    let wherePageEdgeShouldBe = ( window.innerWidth - getRect(bookelement).width ) / 2.0;
    let offset = getRect(anchoredHeading).x - wherePageEdgeShouldBe;

    document.body.scrollLeft += offset;
  }

  function setTextScale(scale) {
    document.documentElement.style.setProperty( "--font-size", `${baseFontSize * scale}px` );
  }

  function toggleNav() {
    if ( navElement.className == "invisible" ) {
      navElement.className = "visible";
    } else {
      navElement.className = "invisible";
    }
  }

  function writePageNumber(pageNumber) {
    window.localStorage.setItem( "pageNumber", pageNumber );
  }

  function readPageNumber() {
    let pageNumber = Number( window.localStorage.getItem("pageNumber") );
    if ( pageNumber > 1 ) {
      console.log(`turning to page ${pageNumber}`)
      turnToPage(pageNumber); // i'm not TOTALLY sure why i need the +1... oh well
    }
  }

  var bookElement;
  var navElement;
  var endElement;
  var baseFontSize = 18.0;
  var lastMouseDown = Date.now();
  var lastClick = Date.now();

  document.addEventListener("DOMContentLoaded", e => {

    bookElement = document.querySelector("div.book");
    navElement = document.querySelector("nav");
    endElement = document.querySelector("p.last-page")

    if (window.innerWidth < 640) {
      setupShadowPages();
    }

    if (window.location.hash.length > 1) { // > 1, because an empty "#" is length 1
      turnToAnchor( window.location.hash )
    } else {
      readPageNumber();
    }

    // toc button

    document.querySelector("button.toc-button").addEventListener("click", e => {
      toggleNav();
      e.stopPropagation();
    });

    // cross button

    document.querySelector("div.close-button").addEventListener("click", e => {
      toggleNav();
      e.stopPropagation();
    });

    // toc text size buttons

    document.querySelectorAll("nav div.controls button").forEach(button => {
      let size = `${baseFontSize * button.dataset.scale}px`;
      button.style.fontSize = size;

      button.addEventListener("click", e => {
        setTextScale(e.target.dataset.scale);
        e.stopPropagation();
      });
    });

    // might delete this later, b/c it is possibly ridiculous:
    // updating the buttons to reflect the "real" base font size

    setTimeout( function(){
      let realFontSize = Number( getComputedStyle(document.documentElement)
                                .getPropertyValue("font-size")
                                .replace("px", "") );
      console.log(`real font size detected: ${realFontSize}px`);

      document.querySelectorAll("nav div.controls button").forEach(button => {
        let size = `${realFontSize * button.dataset.scale}px`;
        button.style.fontSize = size;

        button.addEventListener("click", e => {
          setTextScale(e.target.dataset.scale);
          e.stopPropagation();
        });
      });
    }, 1000);

    // toc chapter links

    document.querySelectorAll("nav a").forEach(link => {

      link.addEventListener("click", e => {
        toggleNav();
        turnToAnchor( e.target.getAttribute("href") )
        e.stopPropagation();
      });
    });

  });

  document.addEventListener("keydown", e => {
    if (event.keyCode === 37) { // left
      turnPageBack();
    }
    if ( (event.keyCode === 39) || (event.keyCode === 32) ) { // right, space
      turnPageForward();
    }
  });

  document.addEventListener("wheel", e => {

    if (navElement.className == "visible") {
      return;
    }

    if ( Math.abs(e.deltaY) > Math.abs(e.deltaX) ) {
      e.preventDefault();
      document.body.scrollLeft += e.deltaY;
    }
  }, { passive: false });

  document.addEventListener("mousedown", function(e) {
    lastMouseDown = Date.now();
  });

  // values in millis
  const CLICK_DEBOUNCE_TIME = 50;
  const LONG_PRESS_TIME = 250;

  document.addEventListener("click", function(e) {

    let now = Date.now();

    // don't advance on long press (text selection?)
    if ( (now - lastMouseDown) > LONG_PRESS_TIME ) {
      return;
    }

    // don't advance on double-click
    if ( (now - lastClick) < CLICK_DEBOUNCE_TIME ) {
      return;
    }

    lastClick = now;

    // don't advance on link click
    if (e.target.tagName == "A") {
      return;
    }

    // don't advance if we are selecting text
    if ( window.getSelection().toString().length > 0 ) {
      return;
    }

    if ( e.clientX < (window.innerWidth / 3.0) ) {
      turnPageBack();
    } else {
      turnPageForward();
    }
  });

  // hash change detector
  // note: it's a window event, not a document event

  window.addEventListener("hashchange", e => {
    if (window.location.hash.length > 1) {
      turnToAnchor( window.location.hash )
    }
  });

  </script>
</head>

<body>

<nav class="invisible">
<div class="controls">
  <button data-scale="0.8">A</button>
  <button data-scale="1.0">A</button>
  <button data-scale="1.2">A</button>
  <button data-scale="1.4">A</button>
  <button data-scale="2.0">A</button>
</div>

<div class="toc">
<h1>Table of Contents</h1>
<div class="close-button">
  <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" width="100%" height="100%" viewBox="0 0 10 10" xml:space="preserve">
  <g>
    <line x1="0" y1="0" x2="10" y2="10" vector-effect="non-scaling-stroke" />
    <line x1="10" y1="0" x2="0" y2="10" vector-effect="non-scaling-stroke" />
  </g>
</svg>
</div>
◊(->html (build-web-toc doc))
</div>
</nav>

<div class="print-cover">
◊(select-from-metas 'title_html metas)
</div>

<div class="book">

<div class="tutorial">
  <h2>How to Read</h2>
  <p><i>On a phone:</i><br/>Swipe, or tap the edges of the page</p>
  <p><i>On a laptop:</i><br/>Use the arrow keys, the space bar, or the touch pad</p>
  <p><i>On a desktop:</i><br/> Use any of the above, or the scroll wheel</p>
  <p>Basically, <small>everything works</small></p>
</div>

<img class="cover" src="◊(select-from-metas 'cover_image metas)" alt="" />
◊(select-from-metas 'title_html metas)

◊(->html doc)
<p class="last-page"></p>

<div class="bookmark">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" width="100%" height="100%" viewBox="0 0 40 80" xml:space="preserve">
  <g>
    <polygon points="0,0 0,80 20,70 40,80 40,0"/>
  </g>
</svg>
</div>

</div>

<div class="shadow-page-container"></div>

<button class="toc-button">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" width="100%" height="100%" viewBox="0 0 80 40" xml:space="preserve">
  <g>
    <rect x="0" y="10" width="5" height="1" />
    <rect x="0" y="20" width="5" height="1" />
    <rect x="0" y="30" width="5" height="1" />

    <rect x="10" y="10" width="70" height="1" />
    <rect x="10" y="20" width="70" height="1" />
    <rect x="10" y="30" width="70" height="1" />
  </g>
</svg>
</button>

</body>
</html>
