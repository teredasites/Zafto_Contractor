'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Save,
  Eye,
  ThumbsUp,
  Inbox,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { getSupabase } from '@/lib/supabase';

interface KnowledgeBaseArticle {
  id: string;
  title: string;
  slug: string;
  content: string;
  category: string;
  tags: string[] | null;
  is_published: boolean;
  view_count: number;
  helpful_count: number;
  created_at: string;
  updated_at: string;
}

function generateSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim();
}

export default function KBArticleEditorPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;
  const isNew = id === 'new';

  const [loading, setLoading] = useState(!isNew);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);

  const [title, setTitle] = useState('');
  const [slug, setSlug] = useState('');
  const [category, setCategory] = useState('');
  const [content, setContent] = useState('');
  const [isPublished, setIsPublished] = useState(false);
  const [viewCount, setViewCount] = useState(0);
  const [helpfulCount, setHelpfulCount] = useState(0);
  const [slugManuallyEdited, setSlugManuallyEdited] = useState(false);

  useEffect(() => {
    if (isNew) return;

    const fetchArticle = async () => {
      const supabase = getSupabase();

      const { data } = await supabase
        .from('knowledge_base')
        .select('*')
        .eq('id', id)
        .single();

      if (data) {
        const article = data as KnowledgeBaseArticle;
        setTitle(article.title);
        setSlug(article.slug);
        setCategory(article.category || '');
        setContent(article.content || '');
        setIsPublished(article.is_published);
        setViewCount(article.view_count);
        setHelpfulCount(article.helpful_count);
        setSlugManuallyEdited(true);
      }
      setLoading(false);
    };

    fetchArticle();
  }, [id, isNew]);

  const handleTitleChange = (value: string) => {
    setTitle(value);
    if (!slugManuallyEdited) {
      setSlug(generateSlug(value));
    }
  };

  const handleSlugChange = (value: string) => {
    setSlug(value);
    setSlugManuallyEdited(true);
  };

  const handleSave = async () => {
    if (!title.trim()) return;

    setSaving(true);
    setSaveError(null);
    setSaveSuccess(false);

    const supabase = getSupabase();

    const articleData: Record<string, unknown> = {
      title: title.trim(),
      slug: slug.trim() || generateSlug(title),
      category: category.trim(),
      content: content.trim(),
      is_published: isPublished,
    };

    if (!isNew) {
      articleData.id = id;
    }

    const { error } = await supabase
      .from('knowledge_base')
      .upsert(articleData);

    if (error) {
      setSaveError(error.message);
    } else {
      setSaveSuccess(true);
      if (isNew) {
        router.push('/dashboard/knowledge-base');
      } else {
        setTimeout(() => setSaveSuccess(false), 3000);
      }
    }
    setSaving(false);
  };

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="flex items-center gap-3">
          <div className="h-8 w-8 rounded skeleton-shimmer" />
          <div className="h-6 w-48 rounded skeleton-shimmer" />
        </div>
        <div className="space-y-4">
          <div className="h-10 w-full rounded-lg skeleton-shimmer" />
          <div className="h-10 w-full rounded-lg skeleton-shimmer" />
          <div className="h-10 w-1/2 rounded-lg skeleton-shimmer" />
          <div className="h-48 w-full rounded-lg skeleton-shimmer" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard/knowledge-base"
            className="p-2 rounded-lg hover:bg-[var(--bg-elevated)] transition-colors text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
          >
            <ArrowLeft className="h-5 w-5" />
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            {isNew ? 'New Article' : 'Edit Article'}
          </h1>
        </div>
        <Button onClick={handleSave} loading={saving} disabled={!title.trim()}>
          <Save className="h-4 w-4" />
          {isNew ? 'Create' : 'Save'}
        </Button>
      </div>

      {/* Save feedback */}
      {saveError && (
        <div className="rounded-lg border border-red-200 bg-red-50 dark:bg-red-950/30 dark:border-red-800 px-4 py-3">
          <p className="text-sm text-red-700 dark:text-red-400">{saveError}</p>
        </div>
      )}
      {saveSuccess && (
        <div className="rounded-lg border border-emerald-200 bg-emerald-50 dark:bg-emerald-950/30 dark:border-emerald-800 px-4 py-3">
          <p className="text-sm text-emerald-700 dark:text-emerald-400">Article saved successfully.</p>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Form */}
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Article Content</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <Input
                  label="Title"
                  value={title}
                  onChange={(e) => handleTitleChange(e.target.value)}
                  placeholder="Article title"
                />
                <Input
                  label="Slug"
                  value={slug}
                  onChange={(e) => handleSlugChange(e.target.value)}
                  placeholder="article-slug"
                />
                <Input
                  label="Category"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  placeholder="e.g. Getting Started, Billing, Features"
                />
                <div className="space-y-1.5">
                  <label className="block text-sm font-medium text-[var(--text-primary)]">
                    Content
                  </label>
                  <textarea
                    value={content}
                    onChange={(e) => setContent(e.target.value)}
                    placeholder="Write article content..."
                    rows={16}
                    className="w-full rounded-lg border border-[var(--border)] bg-[var(--bg-card)] px-3 py-2.5 text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:border-[var(--accent)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 transition-colors resize-y"
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Publishing */}
          <Card>
            <CardHeader>
              <CardTitle>Publishing</CardTitle>
            </CardHeader>
            <CardContent>
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={isPublished}
                  onChange={(e) => setIsPublished(e.target.checked)}
                  className="h-4 w-4 rounded border-[var(--border)] text-[var(--accent)] focus:ring-[var(--accent)]/20"
                />
                <span className="text-sm text-[var(--text-primary)]">
                  Published
                </span>
                <Badge variant={isPublished ? 'success' : 'warning'} className="ml-auto">
                  {isPublished ? 'Live' : 'Draft'}
                </Badge>
              </label>
            </CardContent>
          </Card>

          {/* Stats (existing articles only) */}
          {!isNew && (
            <Card>
              <CardHeader>
                <CardTitle>Statistics</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="flex items-center gap-2 text-sm text-[var(--text-secondary)]">
                      <Eye className="h-4 w-4" />
                      Views
                    </span>
                    <span className="text-sm font-medium text-[var(--text-primary)]">
                      {viewCount}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="flex items-center gap-2 text-sm text-[var(--text-secondary)]">
                      <ThumbsUp className="h-4 w-4" />
                      Helpful
                    </span>
                    <span className="text-sm font-medium text-[var(--text-primary)]">
                      {helpfulCount}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
