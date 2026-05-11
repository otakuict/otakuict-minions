import "./globals.css";

export const metadata = {
  title: "Pokedex",
  description: "Educational Pokedex app using the public Pokemon API"
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

