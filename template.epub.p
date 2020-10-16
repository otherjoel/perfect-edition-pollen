◊(define epub-file (write-epub-files doc metas))
◊(if epub-file (file->bytes epub-file) (error "Error building epub!"))