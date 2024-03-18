/**
 * Function to set authoriation header based on cookies or auth header.
 * @param {*} event Cloudfront viewer request event.
 * @returns Cloudfront viewer request.
 */
function handler(event) {
    var request = event.request;

    // Return if pre-flight request.
    if (request.method === 'OPTIONS') {
        return request;
    }

    var accessToken = request.headers.authorization ? request.headers.authorization.value : undefined;

    if (request.cookies && request.cookies.access_token) {
        accessToken = `Bearer ${request.cookies.access_token.value}`;
    }

    //Add the authorization header to the incoming request
    if (accessToken) {
        request.headers.authorization = { value: `${accessToken}` };
    } else {
        return {
            statusCode: 401,
            statusDescription: 'Unauthorized'
        };
    }

    return request;
}
