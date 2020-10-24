# Perfect Edition (Pollen version)

This is an [Pollen][2] port of Robin Sloan’s [Perfect Edition][1] template for web books
and ebooks. See that repo for a preview of what this looks like.

All that you see here was coded during a live streaming session that is part of my [Pollen Time][pt]
series, where I teach Pollen publishing techniques. The recordings for this particular project are
on YouTube ([Part 1][yt1], [Part 2][yt2]).

[yt1]: https://youtu.be/bleu1mSAFuo 
[yt2]: https://youtu.be/lkF8_xQcbUQ
[pt]: https://buttondown.email/pollentime

For this repo I have substituted a portion of a very old novel, _The King in Yellow_, for Robin’s
own novel, to avoid any copyright transgressions.

If you have Pollen and Racket installed, you can build the ebook like so:

    raco pollen render book.html
    
Or, to generate the ePub file:

    raco pollen render book.epub
    
If you’re editing the book, you might also want to use Pollen’s web server to view your changes live
in the HTML version:

    raco pollen start -l

The `-l` flag will automatically **l**aunch your web browser to `http://localhost:8080/index.ptree`
once the server is started.

Still a bit rough around the edges! Contributions welcome.

[1]: https://github.com/robinsloan/perfect-edition
[2]: https://pollenpub.com
