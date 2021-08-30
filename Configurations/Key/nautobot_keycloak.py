# This goes Below Extra Installed Apps at the bottom of the nautobot_config.py file
AUTHENTICATION_BACKENDS = (
    'social_core.backends.keycloak.KeycloakOAuth2',
    'nautobot.core.authentication.ObjectPermissionBackend',
)

SOCIAL_AUTH_KEYCLOAK_KEY = ''
SOCIAL_AUTH_KEYCLOAK_SECRET = ''
SOCIAL_AUTH_KEYCLOAK_PUBLIC_KEY = \
    ''
SOCIAL_AUTH_KEYCLOAK_AUTHORIZATION_URL = \
    '/auth/realms/master/protocol/openid-connect/auth'
SOCIAL_AUTH_KEYCLOAK_ACCESS_TOKEN_URL = \
    '/auth/realms/master/protocol/openid-connect/token'