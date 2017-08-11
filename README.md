# Kong Userinfo Plugin

This plugin for [Kong](http://getkong.com) adds support for loading
user informaton for the logged in user (in the `x-authenticated-userid` header)
from LDAP and forwarding that information in headers to the backend API.

Currently, the plugin is fairly simplistic but it does the job.

## Installation

For now, you'll have to clone this repository and use `luarocks make`
to install it into Kong. See the
[custom plugin documentation](https://getkong.org/docs/0.10.x/plugin-development/distribution/)
for details.

## Usage

Simply add the plugin to your API, or globally, and set the various options:

- *Base dn*: The LDAP base DN at which to begin searching.
- *Search filter*: A proper LDAP search filter in which `{user}` is replaced
                   with the value of the `x-authenticated-userid` header.
- *Cache ttl*: For how long should results be cached before going back to LDAP?
- *Encode attributes*: List of attributes, comma separated, to encode using
                       MIME Base64. This is useful as the set of characters allowed
                       in HTTP header values is limited. Any value that is a list
                       will have each list item independantly encoded.
- *Convert rdn to rdns*: This is a bit hacky. Since LDAP groups are often
                         represented as DNs and commas are not allowed in HTTP
                         header values (only as value separators), this allows
                         for a human readible and more easily parsable representation
                         of group values. The DN value is converted to a reverse
                         DNS form, similar to Java. Additionally, immediately
                         duplicate elements are collapsed, the RDNs are lowercased,
                         any RDN with dots or values will be quoted. For example,
                         consider the following transformation:

                         `CN=system.admin,OU=groups,OU=ohio,DC=ohio,DC=edu`:
                         `edu.ohio.groups.'system.admin'`
- *Timeout*: How long to wait for search results before timing out.
- *Bind dn*: DN with which to bind to the LDAP database. Note that binding as
             the user is not currently supported.
- *Ldap uri*: A valid LDAP uri
- *Attributes*: A comma separated list of LDAP search attributes.
- *Bind password*: LDAP bind password.
- *Start tls*: Whether or not to use STARTTLS.

Note that all searches use `subtree` scope for now. Additionally,
_each search establishes a connection to the LDAP server_. There is no
connection pooling at the moment so take that into account when setting
the cache TTL.

Finally, headers are formed by prepending the LDAP attribute name with `x-userinfo-`.
