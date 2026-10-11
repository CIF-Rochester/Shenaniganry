#!/bin/bash

SITE_NAME="shenaniganry.cif.rochester.edu"
BASE_DIR="/var/www/posts"
POSTS_DIR="$BASE_DIR/posts"
GENERATOR="$BASE_DIR/posts.sh"
ADD_POST="$BASE_DIR/add_new.sh"
VHOST="/etc/apache2/sites-available/shenaniganry.conf"
ADDPOST_LINK="/bin/addpost"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this installer as root." >&2
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "You need to run this in Debian.  If you want to host this on some other " >&2
    exit 1
fi

echo "This will install the posts system, providing that the requisite scripts and structure are set up in /var/www/posts.  If a pre-existing install exists (A vhost file for Apache, or the addpost command in /bin/bash), it will overwrite this.  "
read -p "Are you sure? (y/n): " -n 1 -r
echo # Move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Cool!  Let's continue installing!  "
else
    echo ": ("
    exit 1
fi

echo "Installing Apache, if need be"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apache2

echo "Creating our new Vhost"
cat > "$VHOST" <<EOF
<VirtualHost *:80>
    ServerName $SITE_NAME
    DocumentRoot "$BASE_DIR"

    <Directory "$BASE_DIR">
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/shenaniganry-error.log
    CustomLog \${APACHE_LOG_DIR}/shenaniganry-access.log combined
</VirtualHost>
EOF

echo "Enable our new Vhost"
a2ensite shenaniganry.conf

echo "creating the /bin/addpost command. "
ln -s "$ADD_POST" "$ADDPOST_LINK"

#This is probably best practice.  I could just chmod 777 everything.  /shrug
find "$BASE_DIR" -type d -exec chmod 755 {} +
find "$BASE_DIR" -type f -exec chmod 644 {} +
chmod 755 "$GENERATOR" "$ADD_POST"
chmod 777 "$BASE_DIR"
chmod 777 "$BASE_DIR"


systemctl enable apache2
systemctl reload apache2

echo "Creating today's introductory post..."
TODAY_FILE="$POSTS_DIR/$(date '+%m%d%y')0.txt"

if [[ ! -f "$TODAY_FILE" ]]; then
    cat > "$TODAY_FILE" <<'POST'
# Welcome to __SITE_NAME__!

**Whoah!**   *Perish the thought!*  I figured it would be a cool idea to have a website like this to showcase what we've been doing down in the lab as of late.  A variation of this used to exist, but involved me writing far too much HTML by hand, so it quickly died off.  This variant is much easier to work with, and even supports pseudo-markdown!
`Pretty nifty`

## Hi

### Hi

#### Hi

##### Hi

###### Hi

~~I'm mean, evil, text~~  (The evil text has been ***VANQUISHED***!)

Here's hoping someone finds joy in the contents of this site!

& < > "

-Hat Jacob
POST

    sed -i "s|__SITE_NAME__|$SITE_NAME|g" "$TODAY_FILE"
    chmod 644 "$TODAY_FILE"
else
    echo "Today's post already exists; leaving it unchanged: $TODAY_FILE"
fi

echo "Generating the website..."
"$GENERATOR"

echo
echo "Installation complete."
echo "Website:    http://$SITE_NAME/"
echo "Posts:      $POSTS_DIR"
echo "Generator:  $GENERATOR"
echo "Add post:   $ADDPOST_LINK"
echo

