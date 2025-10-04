// app/assets/manifest.js

//= link tailwind.css

//= link_tree ./images
//= link_tree ./fonts

// allow Propshaft to find files built under builds/
// (tailwindcss-rails writes tailwind.css here)
// If you link tailwind.css directly as above, this line helps during precompile:
//= link_tree ./builds