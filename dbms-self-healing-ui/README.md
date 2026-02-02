# DBMS Self-Healing Database - UI Dashboard

A comprehensive user interface for monitoring, managing, and visualizing the self-healing capabilities of a database management system.

## 🚀 Features

- Real-time database health monitoring
- Automated healing process visualization
- Performance metrics dashboard
- Error detection and alerting
- Healing recommendations interface
- Historical data analysis

## 🛠️ Tech Stack

- **Framework**: Next.js 16.1.6
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Runtime**: Node.js
- **Package Manager**: npm/yarn

## 📋 Prerequisites

- Node.js (v18 or higher)
- npm or yarn

## 🚀 Getting Started

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/TSR0705/DBMS_PROJECT_SELF-HEALING-DATABASE.git
   cd dbms-self-healing-ui
   ```

2. Install dependencies:
   ```bash
   npm install
   # or
   yarn install
   ```

### Running the Application

1. Development mode:

   ```bash
   npm run dev
   # or
   yarn dev
   ```

2. Open your browser and navigate to [http://localhost:3000](http://localhost:3000)

### Building for Production

```bash
npm run build
# or
yarn build
```

### Running in Production

```bash
npm start
# or
yarn start
```

## 📁 Project Structure

```
├── app/                 # Next.js 13+ App Router
│   ├── globals.css      # Global styles
│   ├── layout.tsx       # Root layout
│   └── page.tsx         # Home page
├── public/              # Static assets
├── components/          # Reusable React components
├── lib/                 # Utility functions
├── styles/              # Additional style files
├── .gitignore          # Git ignore rules
├── .prettierrc         # Prettier configuration
├── .prettierignore     # Prettier ignore rules
├── .editorconfig       # Editor configuration
├── next.config.ts      # Next.js configuration
├── tailwind.config.ts  # Tailwind CSS configuration
├── tsconfig.json       # TypeScript configuration
├── package.json        # Project dependencies and scripts
└── README.md          # Project documentation
```

## 🧪 Scripts

- `npm run dev` - Start the development server
- `npm run build` - Build the application for production
- `npm start` - Start the production server
- `npm run lint` - Run ESLint for code quality

## 🔒 Environment Variables

If you need to configure environment variables, create a `.env.local` file in the root directory:

```env
# Database connection
DATABASE_URL="your_database_url"

# API keys
API_KEY="your_api_key"

# Other configurations
NEXT_PUBLIC_BASE_URL="http://localhost:3000"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Issues

If you encounter any issues, please open an issue in the repository.

## 👥 Authors

- **Tanmay Singh** - [GitHub Profile](https://github.com/TSR0705)

## 🙏 Acknowledgments

- Thanks to the Next.js team for the amazing framework
- Thanks to the Tailwind CSS team for the utility-first CSS framework
- Thanks to the TypeScript team for the static typing

## 📞 Contact

- Email: tanmaysingh8246@gmail.com

---

⭐ If you find this project helpful, please give it a star!
