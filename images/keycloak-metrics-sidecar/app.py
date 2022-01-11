import flask, os, requests
from flask import Response

app = flask.Flask(__name__)
app.config['DEBUG'] =  True

def create_metrics_list():
    # 0. Fetch the DNS and a good request with all details
    kaycloak_dns = os.environ['KEYCLOAK_SC__SVC_NAME']
    admin_username = os.environ['KEYCLOAK_ADMIN_USERNAME']
    admin_password = os.environ['KEYCLOAK_ADMIN_PASSWORD']
    #kaycloak_dns = "https://keycloak.clouddatalab.eu"

    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    data = {'grant_type': 'password', 'username': admin_username, 'password': admin_password, 'client_id': 'admin-cli'}
    token_response = requests.post(kaycloak_dns+'/auth/realms/master/protocol/openid-connect/token', data=data, headers=headers).json()

    admin_token = 'Bearer ' + token_response["access_token"]

    users_response = requests.get(kaycloak_dns+'/auth/admin/realms/datalab-demo/users', headers={'Authorization': admin_token}).json()

    events_response = requests.get(kaycloak_dns+'/auth/admin/realms/datalab-demo/events', headers={'Authorization': admin_token}).json()

    # 1. Users (metrics)
    metrics_list = [
        '# HELP keycloak_registered_events_by_user Users registered keycloaks events by user (username)'
        #,'# TYPE keycloak_registered_events_by_user counter'
    ]

    for user in users_response:
        counter = 0
        for event in events_response:
            if event['userId'] == user['id']:
                counter += 1
        metrics_list += ['keycloak_registered_events_by_user{user="%s"} %d' % (user['username'], counter)]

    return metrics_list


@app.route('/metrics', methods=['GET'])
def metrics():
    response = '\n'.join(create_metrics_list())
    return Response(response, headers={"Content-Type":"text/plain"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9991)