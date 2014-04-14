requirejs.config(
    baseUrl: 'scripts/bower_components'
    enforceDefine: true
    paths:
        app: '../app'
        mixins: '../mixins'
        components: '../components'

        flight: 'flight/lib'
        "skrollr": 'skrollr/dist/skrollr.min'
        "skrollr-stylehseets": 'skrollr-stylesheets-amd/dist/skrollr.stylesheets.min'
        "skrollr-menu": 'skrollr-menu/src/skrollr.menu'
        jquery:
          'http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery'
          'jquery/dist/jquery.min'
        
    shim:
        'jquery.scrollTo':
          deps: ['jquery']
          exports: 'jQuery.fn.scrollTo'
        'skrollr': 
            exports: 'skrollr'
        'skrollr-menu': 
            deps: ['skrollr']
            exports: 'skrollr.menu'
)

define([
  "flight/component"
  "jquery"
  "skrollr"
  "skrollr-stylehseets"
  "skrollr-menu"
  "components/leftSidebar"
  "components/digestSignup"
  "components/sectionBg"
  "components/sections"
  "components/nav"
  ], (flight, $, skrollr, skrollrStylesheets, skrollrMenu, leftSidebar, digestSignup, sectionBg, sections, nav) -> 
  $(->

    # setup vars for the skrollr listener below
    navList = $('nav ol')
    dropdownNav = null;
    transitionPoints = [];
    $(document).on('sectionsTransitionPointsChange', (ev, data) -> 
      transitionPoints := data.transitionPoints
      if dropdownNav then $(document).trigger('readyForSkrollr')
    );
    $(document).on('smallNavReady', (ev, data) ->
      dropdownNav := $('#nav-dropdown')
      if transitionPoints.length > 0 then $(document).trigger('readyForSkrollr')
    );

    $(document).one('readyForSkrollr', (ev, data) ->
      s = skrollr.init(do
        easing:
          swing2: (percentComplete) ->
            Math.pow(percentComplete, 7)

          swing3: (percentComplete) ->
            Math.pow(percentComplete, 1.8)

          cubedroot: (percentComplete) ->
            Math.pow(percentComplete, 1/3)

          swing4: (percentComplete) ->
            Math.pow(percentComplete, 12);

          swing5: (percentComplete) ->
            Math.pow(percentComplete, 4)
        smoothScrollingDuration: 200,

        # We need to manage the active nav section on scroll, 
        # but no way to do that except as a skrollr listener,
        # since real scroll events are never fired on mobile 
        # devices (and wouldn't have the right data anyway).
        # but this listener will depend on some globals, which
        # we set above
        render: (data) ->
          colorToInherit = navList.css('color')
          scrollTop = data.curTop
          activeIndex = 0

          for section, activeIndex in transitionPoints ++ [[Infinity, Infinity]]
            if scrollTop < section[0]
              activeIndex -= 1
              if activeIndex < 0 then activeIndex = void
              break

          # assuming we're beyond the intro screen...
          if(activeIndex != void)
            navList.find('li').removeClass('active').eq(activeIndex).addClass('active')
            dropdownNav.find('li').removeClass('active').eq(activeIndex).addClass('active')
        )

      skrollrStylesheets.init(s);
      skrollrMenu.init(s, do
        handleLink: (linkElm) ->
          if transitionPoints.length > 0
            transitionPoints[$(linkElm).attr('data-transitionpoint')][1]
      );


      $(document).on('animationsChange', (ev, data) -> 
        if data?.keframesOnly 
          skrollrStylesheets.registerKeyframeChange! 
        else s.refresh(data?.elements || void)
      );
    );

    # Init components. The order is significant here.
    # E.g. nav component must exist so that it's registered 
    # its listeners before section component emits the initial
    # transition points. Similarly, bg must be positioned before 
    # the section container calculates the initial offset
    # positions. Could event some of this; not worth the work now.
    leftSidebar.attachTo('header')
    digestSignup.attachTo('#digestForm')
    nav.attachTo('nav')
    sectionBg.attachTo('.bg.starter', {isHomeSection: true})
    sections.attachTo('#content')
    sectionBg.attachTo('.objective .bg')
    void;
  );
)