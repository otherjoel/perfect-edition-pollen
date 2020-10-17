#lang at-exp racket/base

(require "toc.rkt"
         txexpr
         racket/match
         racket/file
         racket/string
         racket/system
         racket/path
         pollen/setup
         pollen/template)

; Anatomy of an ePub file:
;
;  ┌─────────┐  ┌──────────┐
;  │ List of │  │ List of  │                                 ┌──────────────────┐
;  │  font   │  │  images  │   ┌─────────────────────┐   ┌ ─▶│    ToC Items     │
;  │  files  │  │          │   │Book content (XHTML) │─ ─    └──────────────────┘
;  └─────────┘  └──────────┘   └─────────────────────┘                 │
;       │             │                   │                            │
;       │             │                   │                    ┌───────┴──────┐
;       └───────┬─────┘                   │                    │              │
;               │                         │                    │              │
;               ▼                         ▼                    ▼              ▼
;    ┌─────────────────────┐   ┌─────────────────────┐  ┌────────────┐  ┌───────────┐
;    │     (Manifest)      │   │     (The Book)      │  │ nav.xhtml  │  │  toc.ncx  │
;    │      book.opf       │   │ SLUG-content.xhtml  │  │            │  │           │
;    └─────────────────────┘   └─────────────────────┘  └────────────┘  └───────────┘
;
; These four key files get placed into a folder with other supporting files thusly:
;
; - mimetype
; + BOOK/
;   - book.opf
;   - SLUG-content.xhtml
;   - nav.xhtml
;   - toc.ncx
;   - epub.css         Copied from CSS folder
;   + img/             Contains all images, copied in
;   + font/            Contains all fonts, copied in
;   + META-INF
;     - container.xml  Static
;     - com.apple.ibooks.display-options.xml


;; ePub functions
(provide xml-id-root       ; Root portion of an XML identifier
         images-subfolder  ; Defaults to "img", must contain ONLY images
         fonts-subfolder   ; Defaults to "font", must contain ONLY woff2 fonts
         write-epub-files) ; Builds and zips up an ePub file

(define images-subfolder (make-parameter (string->path "img")))
(define fonts-subfolder (make-parameter (string->path "font")))

;; Root portion of some world-global identifier used in the XML
(define xml-id-root (make-parameter "com.google"))

(define (mimetype filepath)
  (match (path-get-extension filepath)
    [#".png" "image/png"]
    [(or #".jpeg" #".jpg") "image/jpeg"]
    [#".woff2" "font/woff2"]))

;; Builds an x-expr for use in the manifest
;; extra-attr should be a 1-arity function that returns a single key-value pair
(define (manifest-items [subfolder (current-project-root)]
                        [extra-attr (λ (x) null)])
  (define files (directory-list (build-path (current-project-root) subfolder)))

  (string-append*
   (map ->html
        (for/list ([ip (in-list files)]
                   [ctr (in-naturals)])
          (define item-tag
          `(item ((id ,(number->string ctr))
                       (href ,(path->string (build-path subfolder ip)))
                       (media-type ,(mimetype ip)))))
          (match (extra-attr (build-path subfolder ip))
            [(list key val) (attr-set item-tag key val)]
            [_ item-tag])))))

(define (manifest-image-items cover-filename)
  (define (maybe-cover filepath)
    (cond
      [(string=? cover-filename (path->string filepath)) '(properties "cover-image")]
      [else null]))
  (manifest-items (images-subfolder) maybe-cover))

(define (manifest-font-items)
  (manifest-items (fonts-subfolder)))
                 
(define (epub-content-xhtml-string metas body-html)
    @string-append{
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
  
  @string-append{
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

;; Returns an HTML string containing an ordered list of links to
;; headings in the main content file
(define (epub-nav-toc slug items)
  (define list-items
    (for/list ([t (in-list items)])
      `(li (a [[href ,(format "~a-content.xhtml#~a" slug (toc-item-anchor t))]]
              ,@(toc-item-title-elements t)))))
  (->html `(ol ,@list-items)))


(define (epub-nav-xhtml-string metas toc-items)
  (define slug (hash-ref metas 'slug))
  @string-append{
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

 <li><a epub:type="bodymatter" href="@|slug|-content.xhtml#bodymatter">bodymatter</a></li>
 </ol>
 </nav>

 </body>
 </html>})

;; Same as epub-nav-toc but in the format needed for the NCX file
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
  @string-append{
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

;; String constants for misc files needed in the epub
;;
(define ibooks-display-xml #<<END
<?xml version="1.0" encoding="UTF-8"?>
<display_options>
  <platform name="*">
    <option name="specified-fonts">true</option>
  </platform>
</display_options>
END
  )

(define container-xml #<<END
<?xml version="1.0" encoding="UTF-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="BOOK/book.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
END
  )

(define (copy-files-to src-folder dest-folder)
  (for ([f (in-directory src-folder)])
    (define-values (_ the-file x) (split-path f))
    (copy-file f (build-path dest-folder the-file))))

(define (write-epub-files doc metas)
  (define toc-structs (toc-items doc))
  (define slug (hash-ref metas 'slug))
  (define epub-filename (format "~a.epub" slug))

  ;; The string content of the 4 core files (diagram at top of thie module)
  (define content-str (epub-content-xhtml-string metas (->html doc)))
  (define manifest-str (epub-manifest-xhtml-string metas))
  (define nav-str (epub-nav-xhtml-string metas toc-structs))
  (define ncx-str (epub-ncx-xhtml-string metas toc-structs))

  ;; Directory structure:
  (define work-dir (build-path (current-project-root) "build" "epub"))
  (define core-dir (build-path work-dir "BOOK"))
  (define meta-dir (build-path work-dir "META-INF"))

  (delete-directory/files (build-path (current-directory) "build")
                          #:must-exist? #f)

  (make-directory* core-dir)
  (make-directory* meta-dir)

  ;; Write out the 4 core files
  (display-to-file content-str (build-path core-dir (format "~a-content.xhtml" slug)))
  (display-to-file manifest-str (build-path core-dir "book.opf"))
  (display-to-file nav-str (build-path core-dir (format "~a-nav.xhtml" slug)))
  (display-to-file ncx-str (build-path core-dir "toc.ncx"))

  (display-to-file "application/epub+zip" (build-path work-dir "mimetype"))
  (display-to-file ibooks-display-xml (build-path meta-dir "com.apple.ibooks.display-options.xml"))
  (display-to-file container-xml (build-path meta-dir "container.xml"))

  (copy-directory/files (build-path (current-project-root) (images-subfolder))
                        (build-path core-dir (images-subfolder)))
  (copy-directory/files (build-path (current-project-root) (fonts-subfolder))
                        (build-path core-dir (fonts-subfolder)))
  (copy-file (build-path (current-project-root) "css" "epub.css")
             (build-path core-dir "epub.css"))

  (define build-command
    @string-append{
     cd build/epub;
     zip -X0 @epub-filename mimetype;
     zip -r @epub-filename META-INF BOOK})

  (if (system build-command)
      (build-path work-dir epub-filename)
      (error "Error building epub file!")))
