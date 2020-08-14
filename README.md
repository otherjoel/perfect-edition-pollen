# Perfect Edition (Pollen version)

This is an **unfinished** [Pollen][2] port of Robin Sloan’s [Perfect Edition][1] template for web books
and ebooks. See that repo for a preview of what this looks like.

All that you see here was coded during a live streaming session that is part of my [Pollen Time][pt]
series, where I teach Pollen publishing techniques. The recording for this particular session is [on
YouTube][yt1].

[yt1]: https://youtu.be/bleu1mSAFuo 
[pt]: https://buttondown.email/pollentime

For this repo I have substituted a portion of a very old novel, _The King in Yellow_, for Robin’s
own novel, to avoid any copyright transgressions. 

If you have Pollen and Racket installed, you can build the ebook like so:

    raco pollen render book.html
    
When the ePub template is ported, you will be able generate it with the same command (substitute
`book.epub` for the final argument).

If you’re editing the book, you might also want to use Pollen’s web server to view the HTML file:

    raco pollen start

Then browse to `http://localhost:8080/index.ptree`. 

[1]: https://github.com/robinsloan/perfect-edition
[2]: https://pollenpub.com
