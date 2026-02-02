interface PageHeaderProps {
  title: string;
  description?: string;
}

// Console page header - provides visual anchoring and context
export function PageHeader({ title, description }: PageHeaderProps) {
  return (
    <header className="mb-8">
      <h1 className="text-2xl font-semibold text-neutral-900 mb-2">{title}</h1>
      {description && (
        <p className="text-sm text-neutral-600 leading-relaxed max-w-3xl">
          {description}
        </p>
      )}
      <div className="mt-6 h-px bg-neutral-200" />
    </header>
  );
}
