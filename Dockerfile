FROM basefreeradius

# Add user to container with home directory
RUN useradd -m -d /home/micbn -s /bin/bash micbn

# Add password to micbn account
RUN echo 'micbn:micbnpassword4321' | chpasswd

# Edit /etc/pam.d/radiusd file
RUN echo "#%PAM-1.0" > /etc/pam.d/radiusd
RUN echo "account    include      password-auth" >> /etc/pam.d/radiusd
RUN echo "auth requisite pam_google_authenticator.so forward_pass secret=/etc/raddb/\${USER}/.google_authenticator user=root" >> /etc/pam.d/radiusd
RUN echo "auth required pam_unix.so use_first_pass" >> /etc/pam.d/radiusd

# Edit /etc/raddb/mods-config/files/authorize file
# This is the real file for /etc/raddb/users
RUN sed -i '1s/^/# Instruct FreeRADIUS to use PAM to authenticate users\n/' /etc/raddb/mods-config/files/authorize
RUN sed -i '2s/^/DEFAULT Auth-Type := PAM\n/' /etc/raddb/mods-config/files/authorize

# Copy existing /etc/freeradius/sites-available/default file to container
# This is the real file for /etc/raddb/sites-enabled/default
COPY default /etc/raddb/sites-available/default
RUN chown radiusd:radiusd /etc/raddb/sites-available/default

# Copy existing /etc/freeradius/clients.conf file to container
COPY clients.conf /etc/raddb/clients.conf
RUN chown radiusd:radiusd /etc/raddb/clients.conf

COPY server.pem /etc/raddb/certs/server.pem
COPY ca.pem /etc/raddb/certs/ca.pem
COPY dh /etc/raddb/certs/dh
RUN chown -R radiusd:radiusd /etc/raddb/certs/

COPY radiusd.conf /etc/raddb/radiusd.conf
RUN chown radiusd:radiusd /etc/raddb/radiusd.conf

# Create a symbolic link to enable pam
RUN ln -s /etc/raddb/mods-available/pam /etc/raddb/mods-enabled/pam

RUN mkdir /etc/raddb/micbn
COPY .google_authenticator /etc/raddb/micbn
RUN chown -R root.root /etc/raddb/micbn/.google_authenticator

# COPY .google_authenticator /home/micbn
# RUN chown micbn.micbn /etc/raddb/micbn/.google_authenticator

# Expose the port
EXPOSE 1812/udp 1813/udp 18120/udp

# Run FreeRADIUS as a foreground process
CMD ["radiusd","-X"]