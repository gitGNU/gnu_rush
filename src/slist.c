/* This file is part of Rush.                  
   Copyright (C) 2008 Sergey Poznyakoff

   Rush is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3, or (at your option)
   any later version.

   Rush is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with Rush.  If not, see <http://www.gnu.org/licenses/>. */

#include <rush.h>

struct line_list {
	struct line_list *next;
	size_t size;
	char line[1];
};

struct slist {
	struct line_list *head, *tail;
	size_t size;
};

struct line_list *
new_line_seg(const char *p, size_t len)
{
	struct line_list *lp = xmalloc(sizeof(*lp) + len);
	lp->next = NULL;
	memcpy(lp->line, p, len);
	lp->size = len;
	return lp;
}

void
slist_append(slist_t slist, const char *p, size_t len)
{
	struct line_list *lp = new_line_seg(p, len);
	LIST_APPEND(lp, slist->head, slist->tail);
	slist->size += len;
}

char *
slist_reduce(slist_t slist, char **pbuf, size_t *psize)
{
	struct line_list *lp;
	size_t total = slist->size + 1;
	char *s;
	if (*psize < total) {
		if (!*pbuf)
			*pbuf = xmalloc(total);
		else
			*pbuf = xrealloc(*pbuf, total);
		*psize = total;
	}
	s = *pbuf;
	for (lp = slist->head; lp; ) {
		struct line_list *next = lp->next;
		memcpy(s, lp->line, lp->size);
		s += lp->size;
		free(lp);
		lp = next;
	}
	*s++ = 0;
	slist->head = slist->tail = NULL;
	slist->size = 0;
	return *pbuf;
}

slist_t
slist_create()
{
	slist_t p = xzalloc(sizeof(*p));
	return p;
}

void
slist_free(slist_t slist)
{
	struct line_list *lp;
	for (lp = slist->head; lp; ) {
		struct line_list *next = lp->next;
		free(lp);
		lp = next;
	}
	free(slist);
}

