module.exports = {
    build: {
        templates: {
            // compile every file in src/emails/*.html
            source: 'maizzle/src/emails',
            destination: {
                path: 'maizzle/build'
            }
        },
        tailwind: {
            config: 'tailwind.email.config.js'
        },
        inlineCSS: true
    },
    inlineCSS: true
}