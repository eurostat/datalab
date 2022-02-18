import flask, sys, os, requests, smtplib, ssl, json

from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import request, Response, render_template

app = flask.Flask(__name__)
app.config['DEBUG'] =  True

def kc_admin_token_password_grant(keycloak_dns, admin_username, admin_password):
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    data = {'grant_type': 'password', 'username': admin_username, 'password': admin_password, 'client_id': 'admin-cli'}
    token_response = requests.post(keycloak_dns+'/auth/realms/master/protocol/openid-connect/token', data=data, headers=headers).json()
    return token_response["access_token"]

def get_email_list(keycloak_dns, admin_token, alerts):
    # Create email content per user
    email_contents = {}
    for alert in alerts:
        username = alert["labels"]["exported_namespace"].replace("user-", "")

        if username not in email_contents:
            email_contents[username] = []
        
        for k,v in alert["annotations"].items():
            email_contents[username].append(k+': '+v)
        email_contents[username].append("")

    # create email list to send
    email_list = []
    for username, content in email_contents.items():
        # get the email
        try:
            query = '?exact=true&username='+username
            user_email = requests.get(keycloak_dns+'/auth/admin/realms/datalab-demo/users'+query, headers={'Authorization': 'Bearer ' + admin_token}).json()[0]["email"]
        except:
            print("User does not exist / Error getting email", file=sys.stdout)
            continue

        # create the email
        message = MIMEMultipart("alternative")
        message["Subject"] = "Datalab Notification"
        message["From"] = "datalab-no-reply"
        message["To"] = user_email

        mimed_body = MIMEText(render_template('email.html', content=content, username=username), "html")
        message.attach(mimed_body)

        # append to the object
        email_list.append({
            "to": user_email,
            "message": message.as_string()
        })

    return email_list


def send_emails(email_list, smtp_server, smtp_server_port, smtp_user, smtp_password):
    context = ssl.create_default_context()

    with smtplib.SMTP(smtp_server, smtp_server_port) as server:
        server.ehlo()
        server.starttls(context=context)
        server.ehlo()
        server.login(smtp_user, smtp_password)
        for email in email_list:
            server.sendmail(smtp_user, email["to"], email["message"])
        server.close()

@app.route('/webhook', methods=['POST'])
def notify_users():
    # -1. only treat this if it's an alert to notify users
    if not request.get_data():
        return Response('', 400)
    data = json.loads(request.get_data().decode('utf8').replace("'", '"'))
    user_alerts = [alert for alert in data["alerts"] if 'exported_namespace' in alert["labels"]]
    if not user_alerts:
        return Response('Not a user notification.', 200)

    # 0. pick-up all the env variables!!
    keycloak_dns = os.environ['KEYCLOAK_SC__SVC_NAME']
    admin_username = os.environ['KEYCLOAK_ADMIN_USERNAME']
    admin_password = os.environ['KEYCLOAK_ADMIN_PASSWORD']
    smtp_server = os.environ['SMTP_SERVER']
    smtp_server_port = os.environ['SMTP_SERVER_PORT']
    smtp_user = os.environ['SMTP_USERNAME']
    smtp_password = os.environ['SMTP_PASSWORD']

    # 1. get Keycloak admin token
    admin_token = kc_admin_token_password_grant(keycloak_dns, admin_username, admin_password)
    
    # 2. For every alert in the alerts group list get an email to send
    email_list = get_email_list(keycloak_dns, admin_token, user_alerts)

    # 3. send the emails
    try:
        send_emails(email_list, smtp_server, smtp_server_port, smtp_user, smtp_password)
    except Exception as e:
        print("Failed to send emails:\n", file=sys.stdout)
        print(email_list, file=sys.stdout)
        print(e, file=sys.stdout)

    return Response('', 204)



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9992)