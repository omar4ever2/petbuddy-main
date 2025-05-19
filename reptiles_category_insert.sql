-- SQL to add Reptiles category with dragon icon

INSERT INTO public.categories (
    name,
    description,
    icon_name,
    image_url,
    created_at,
    updated_at
) VALUES (
    'Reptiles',
    'Supplies and accessories for reptiles and amphibians',
    'dragon',
    'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?q=80&w=200',
    NOW(),
    NOW()
); 