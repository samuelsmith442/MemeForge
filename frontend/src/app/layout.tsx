import './globals.css';

export const metadata = {
  title: 'MemeForge - AI-Powered Memecoin Creation',
  description: 'Create unique memecoins with AI-generated logos and smart contracts',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
