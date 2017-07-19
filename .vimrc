nmap <leader>y :!clear && bundle exec yard doc<cr>
nmap <leader>l :w<cr>:!clear && bundle exec rubocop %<cr>
nmap <leader>L :w<cr>:!clear && bundle exec rubocop --auto-correct %<cr>
let g:test#last_position = {'file': 'spec/rschema_spec.rb', 'col': 1, 'line': 1}
