'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Search,
  BookOpen,
  Eye,
  ThumbsUp,
  Plus,
  Filter,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { getSupabase } from '@/lib/supabase';
import { formatRelativeTime } from '@/lib/utils';

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

export default function KnowledgeBasePage() {
  const [articles, setArticles] = useState<KnowledgeBaseArticle[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [publishedFilter, setPublishedFilter] = useState<'all' | 'published' | 'draft'>('all');

  useEffect(() => {
    const fetchArticles = async () => {
      const supabase = getSupabase();

      const { data } = await supabase
        .from('knowledge_base')
        .select('*')
        .order('updated_at', { ascending: false });

      if (data) {
        setArticles(data as KnowledgeBaseArticle[]);
      }
      setLoading(false);
    };

    fetchArticles();
  }, []);

  const filtered = articles.filter((a) => {
    const matchesSearch = a.title.toLowerCase().includes(search.toLowerCase());
    const matchesPublished =
      publishedFilter === 'all' ||
      (publishedFilter === 'published' && a.is_published) ||
      (publishedFilter === 'draft' && !a.is_published);
    return matchesSearch && matchesPublished;
  });

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Knowledge Base
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            {articles.length} articles
          </p>
        </div>
        <Link href="/dashboard/knowledge-base/new">
          <Button>
            <Plus className="h-4 w-4" />
            New Article
          </Button>
        </Link>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative max-w-md flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[var(--text-secondary)]" />
          <Input
            placeholder="Search articles..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <div className="relative">
          <Filter className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[var(--text-secondary)]" />
          <select
            value={publishedFilter}
            onChange={(e) => setPublishedFilter(e.target.value as 'all' | 'published' | 'draft')}
            className="appearance-none rounded-lg border border-[var(--border)] bg-[var(--bg-card)] pl-9 pr-8 py-2.5 text-sm text-[var(--text-primary)] focus:border-[var(--accent)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 transition-colors"
          >
            <option value="all">All Articles</option>
            <option value="published">Published</option>
            <option value="draft">Drafts</option>
          </select>
        </div>
      </div>

      {/* Grid */}
      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Card key={i}>
              <div className="space-y-3">
                <div className="h-5 w-3/4 rounded skeleton-shimmer" />
                <div className="h-4 w-1/2 rounded skeleton-shimmer" />
                <div className="flex gap-2 mt-4">
                  <div className="h-5 w-20 rounded-full skeleton-shimmer" />
                  <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                </div>
              </div>
            </Card>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <Card>
          <CardContent>
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <BookOpen className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm">No articles found</p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.map((article) => (
            <Link key={article.id} href={`/dashboard/knowledge-base/${article.id}`}>
              <Card hover>
                <div className="space-y-3">
                  <h3 className="text-[15px] font-semibold text-[var(--text-primary)] line-clamp-2">
                    {article.title}
                  </h3>
                  <div className="flex items-center gap-2 flex-wrap">
                    {article.category && (
                      <Badge>{article.category}</Badge>
                    )}
                    <Badge variant={article.is_published ? 'success' : 'warning'}>
                      {article.is_published ? 'Published' : 'Draft'}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-4 text-xs text-[var(--text-secondary)]">
                    <span className="flex items-center gap-1">
                      <Eye className="h-3.5 w-3.5" />
                      {article.view_count}
                    </span>
                    <span className="flex items-center gap-1">
                      <ThumbsUp className="h-3.5 w-3.5" />
                      {article.helpful_count}
                    </span>
                    <span className="ml-auto">
                      {formatRelativeTime(article.updated_at)}
                    </span>
                  </div>
                </div>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
