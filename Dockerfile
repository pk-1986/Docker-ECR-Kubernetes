# Use the official Ubuntu base image
FROM ubuntu:latest

# Update the package list and install Apache2
RUN apt-get update && apt-get install -y apache2

# Expose port 80
EXPOSE 80
COPY index.html /var/www/html/

# Start Apache2 service
CMD ["apache2ctl", "-D", "FOREGROUND"]
