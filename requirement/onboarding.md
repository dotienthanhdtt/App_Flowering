#Here is requirement for onboarding flow and some update for app

## Ref file
- API design '../docs/api_docs/auth-api.md'
- Design pencil mcp file design.pen
## Update
- Update base url for dev env https://dev.broduck.me
- Swagger docs https://dev.broduck.me/api/docs

## Onboarding flow
1: Splash screen for 3 secs, in while check token valid (if token is null, empty 
or expire when call api get user/me or refresh to check) if not valid go to screen 1A, if valid go to home screen
2: implement screen 0, 1A, 1B, 1C, 2, 3, with mock data