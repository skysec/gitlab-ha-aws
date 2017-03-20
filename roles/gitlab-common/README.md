Gitlab Common
========

Creates an image fully configured with GitLab, using ensible and gitlab omnibus

Requirements
------------

Ansible standard modules are used by this role

Role Variables
--------------

* system_fqdn: Fully domain name of the system
* gitlab_user: Gitlab default user
* gitlab_datadir: Data/Repo directory
* gitlab_root_email: "root@example.com"
* postgres_gitlab_user: "git"
* postgres_gitlab_pass: Password of the DB
* postgres_gitlab_ext: "pg_trgm"
* postgres_gitlab_dbname: Name of the Database`
* postgres_host: DB host DNS name / IP
* postgres_user: "{{ postgres_gitlab_user }}"
* postgres_pass: "{{ postgres_gitlab_pass }}"
* unicorn_workers: "3"
* redis_host: redis endpoint
* redis_port: "6379"
* efs_dnsname: NFS server DNS name / IP
* gitlab_ssl_dir: Directory to store the SSL Certificate and Private Key
* gitlab_ssl_dn: Certificate Distinguished Name


License
-------

BSD

