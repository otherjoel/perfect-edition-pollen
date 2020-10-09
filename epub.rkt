#lang at-exp racket/base

(require "toc.rkt"
         txexpr
         racket/match
         racket/string
         racket/path
         pollen/template)

;; ePub functions
(provide xml-id-root
         images-folder  ; Defaults to "img", must contain ONLY images
         fonts-folder   ; Defaults to "font", must contain ONLY woff2 fonts
         epub-content-xhtml-string   ; For main content file
         epub-manifest-xhtml-string  ; Manifest
         epub-nav-xhtml-string       ; Table of contents
         epub-ncx-xhtml-string)      ; Alternate table of contents

(define images-folder (make-parameter (build-path (current-directory) "img")))
(define fonts-folder (make-parameter (build-path (current-directory) "font")))

;; Root portion of some world-global identifier used in the XML
(define xml-id-root (make-parameter "com.google"))

(define (mimetype filepath)
  (match (path-get-extension filepath)
    [#".png" "image/png"]
    [(or #".jpeg" #".jpg") "image/jpeg"]
    [#".woff2" "font/woff2"]))

(define (manifest-items [folder (current-directory)]
                        [extra-attr (λ (x) null)])
  (define files (directory-list folder))

  (string-append*
   (map ->html
        (for/list ([ip (in-list files)]
                   [ctr (in-naturals)])
          `(item
            ,(append `((id (number->string ctr))
                       (href ,(path->string ip))
                       (media-type ,(mimetype ip)))
                     (extra-attr ip)))))))

(define (manifest-image-items cover-filename)
  (define (maybe-cover filepath)
    (cond
      [(string=? cover-filename (path->string filepath)) '(properties "cover-image")]
      [else null]))
  (manifest-items images-folder maybe-cover))

(define (manifest-font-items)
  (manifest-items fonts-folder))
                 
(define (epub-content-xhtml-string metas body-html)
  @string-append*{
 <?xml version="1.0" encoding="UTF-8"?>
 <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"
 xmlns:epub="http://www.idpf.org/2007/ops">
 <head>
 <meta charset="utf-8" />
 <title>@(hash-ref metas 'title)</title>
 <link rel="stylesheet" type="text/css" href="epub.css" />
 </head>
 <body>
 <section epub:type="frontmatter" id="frontmatter">
 <section epub:type="titlepage" id="titlepage">
 @(hash-ref metas 'title-html)
 </section>
 </section>
 <section epub:type="bodymatter" id="bodymatter">
 @body-html
 </section>
 </body>
 </html>})
    
(define (epub-manifest-xhtml-string metas)
  (define slug (hash-ref metas 'slug))
  (define pub-date (hash-ref metas 'pub-date))
  (define modified-date (or (hash-ref metas 'modified-date #f) pub-date))
  
  @string-append*{
 <?xml version="1.0" encoding="UTF-8"?>
 <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uid" xml:lang="en-US" prefix="cc: http://creativecommons.org/ns#">
 <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
 <dc:identifier id="uid">@(xml-id-root).@|slug|</dc:identifier>
 <dc:title>@(hash-ref metas 'title)</dc:title>
 <dc:creator>@(hash-ref metas 'author)</dc:creator>
 <dc:language>en-US</dc:language>
 <dc:date>@|pub-date|</dc:date>
 <dc:description>@(hash-ref metas 'description)</dc:description>
 <meta property="dcterms:modified">@|modified-date|</meta>
 <dc:rights>This work is shared with the public using the Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license.</dc:rights>
 <link rel="cc:license" href="http://creativecommons.org/licenses/by-sa/3.0/"/>
 <meta property="cc:attributionURL">@(hash-ref metas 'home-url)</meta>
 </metadata>
 <manifest>
 <item id="@|slug|" href="@|slug|-content.xhtml" media-type="application/xhtml+xml" />
 <item id="nav" href="@|slug|-nav.xhtml" properties="nav" media-type="application/xhtml+xml" />
 <item id="css" href="epub.css" media-type="text/css" />

 @(manifest-image-items (hash-ref metas 'cover-image))

 @(manifest-font-items)

 <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />
 </manifest>
 <spine toc="ncx">
 <itemref idref="@slug" />
 </spine>
 </package>})

(define (epub-nav-toc slug items)
  (define list-items
    (for/list ([t (in-list items)])
      `(li (a [[href ,(format "~a-content.xhtml#~a" slug (toc-item-anchor t))]]
              ,@(toc-item-title-elements t)))))
  (->html `(ol ,@list-items)))

(define (epub-nav-xhtml-string metas toc-items)
  (define slug (hash-ref metas 'slug))
  @string-append*{
 <?xml version="1.0" encoding="UTF-8"?>
 <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"
 xmlns:epub="http://www.idpf.org/2007/ops">
 <head>
 <meta charset="utf-8" />
 <link rel="stylesheet" type="text/css" href="epub.css" />
 <title>@(hash-ref metas 'title)</title>
 </head>
 <body>
 <nav epub:type="toc" id="toc">
 @(epub-nav-toc slug toc-items)
 </nav>
 <nav epub:type="landmarks">
 <ol>

 <li><a epub:type="frontmatter" href="@|slug|-content.xhtml#frontmatter">frontmatter</a></li>

 <li><a epub:type="bodymatter" href=""@|slug|-content.xhtml#bodymatter">bodymatter</a></li>
 </ol>
 </nav>

 </body>
 </html>})

(define (epub-ncx-toc slug items)
  (define list-items
    (for/list ([t (in-list items)])
      (define src (format "~a-content.xhtml#~a" slug (toc-item-anchor t)))
      `(navpoint [[id ,(toc-item-anchor t)]]
                 (navLabel (text ,@(toc-item-title-elements t)))
                 (content [[src ,src]]))))
  (->html `(navMap ,@list-items)))

(define (epub-ncx-xhtml-string metas toc-items)
  (define slug (hash-ref metas 'slug))
  @string-append*{
 <?xml version="1.0" encoding="UTF-8"?>
 <ncx xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/" xmlns="http://www.daisy.org/z3986/2005/ncx/"
 version="2005-1" xml:lang="en">
 <head>
 <meta name="dtb:uid" content="@(xml-id-root).@slug"/>
 </head>
 <docTitle>
 <text>@(hash-ref metas 'title)</text>
 </docTitle>
 @(epub-ncx-toc slug toc-items)
 </ncx>})