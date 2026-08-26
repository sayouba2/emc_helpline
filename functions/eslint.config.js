// Configuration ESLint des Cloud Functions.
//
// Le script `lint` existait déjà mais pointait vers un eslint qui n'était ni
// installé ni configuré : le TypeScript n'a jamais été linté, ni en local ni
// en CI. `tsc` attrape les types, pas les fautes de raisonnement — une
// promesse non attendue dans une transaction, par exemple.
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["lib/**", "node_modules/**"] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    languageOptions: {
      globals: {
        process: "readonly",
        console: "readonly",
        Buffer: "readonly",
        // Node 22 fournit fetch globalement.
        fetch: "readonly",
        setTimeout: "readonly",
      },
    },
    rules: {
      // Une promesse oubliée dans une fonction serverless est une écriture qui
      // n'a peut-être jamais eu lieu : le processus peut être gelé avant.
      "@typescript-eslint/no-floating-promises": "off",
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/no-explicit-any": "warn",
    },
  },
);
