function utility_pushover(app,message)

token_input_path = 'pushover.token';
read_config(token_input_path,[tempdir,token_input_path,'.mat']);
load([tempdir,token_input_path,'.mat'])

post_params = {'token', api_token,...      % API token
               'user', user_token,...      % user's ID token
               'message', message,...      % message to push
               'title', ['UQXPOL - ',app]}; % message title in notification bar
           
urlread('https://api.pushover.net/1/messages.json', 'Post', post_params);