FROM nginx:alpine

COPY templates/ /usr/share/nginx/html/
COPY css/ /usr/share/nginx/html/css/
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template

# Default for local docker-compose; overridden per environment (e.g. Azure Container Apps)
ENV ENROLMENT_SERVICE_URL=http://enrolment-service:5001

EXPOSE 80