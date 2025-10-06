const fs = require('fs');
const path = require('path');

const map = [
    {
        src: 'maizzle/build/reset_password.html',
        dest: 'app/views/devise/mailer/reset_password_instructions.html.erb'
    },
    {
        src: 'maizzle/build/_layouts/base.html',
        dest: 'app/views/layouts/mailer.html.erb'
    }
];

for (const {src, dest} of map) {
    const html = fs.readFileSync(path.resolve(src), 'utf8');
    // replace Maizzle variables with Rails ERB
    const transformed = html
        .replace(/{{\s*reset_url\s*}}/g, '<%= @token_url %>'); // we will provide @token_url
    fs.mkdirSync(path.dirname(dest), {recursive: true});
    fs.writeFileSync(dest, transformed, 'utf8');
    console.log(`Wrote ${dest}`);
}