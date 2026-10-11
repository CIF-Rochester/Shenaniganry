# Shenaniganry
A quick and easy way to make posts to a static HTML website.  

Whoah!  You've found the README file, and even bothered to read it!

This project is pretty simple.  It is a static HTML generator serving a number of easy-to-write posts (with pseudo-markdown, saved as txt files).
The main functionality is provided by a bash script (posts.sh), meant to be re-generated periodically.  A script called add_new.sh will help you create a new post and publish them to the website.  A symlink of this script lives in /bin/addpost.  

A third script is included to help you install it (install.sh).  Make sure the contents of this repo are placed inside of /var/www/posts.  (Needed if the script is to work properly by default).  If you choose to change this location, change the script, etc.  

Posts are stored in txt form inside of the posts directory (/var/www/posts/posts).  The names of these matter.  They are of the form MMDDYY#.txt.  So, the first post of October 7th, 2026 would be 1007260.txt, the second post of that day being 1007261.txt, and so forth.  This is where the script gets the date from.

If you wish to make a new script, add a file into posts, named appropriately, and regenerate the posts file.  /bin/addpost does this for you.  

Pseudo-Markdown?
This file supports a number of Markdown characters, and automatically converts them into their appropriate HTML counterparts.
Namely, it supports
#           H1
##          H2
###         H3
####        H4
#####       H5
######      H6
*Italics*
**Bold**
`Codeblock`
~~Strikethrough~~

I'd recommend having a title with `#`, and signing off with your name, or a nickname if you so desire).  The script will automatically publish the account name of the owner of the txt file at the bottom of each post on the website.  

The script will add the newest post to the top of the 

This site is presently hosted at http://shenaniganry.cif.rochester.edu/ and the files are located at /var/www/posts on Korvax.  
