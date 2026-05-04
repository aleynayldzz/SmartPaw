/**
 * Flutter `assets/images/breeds/*` ile aynı mantıkta avatar_url:
 * mobil istemci bu yolu yerel bundle görseline çevirir veya CDN URL kullanır.
 *
 * @param { import("knex").Knex } knex
 */
exports.seed = async function seed(knex) {
  const breeds = [
    ["Ankara", "ankara", "assets/images/breeds/ankara.png"],
    ["Balinese", "balinese", "assets/images/breeds/balinese.png"],
    ["Bengal", "bengal", "assets/images/breeds/bengal.png"],
    ["Birman", "birman", "assets/images/breeds/birman.jpeg"],
    ["Bombay", "bombay", "assets/images/breeds/bombay.png"],
    ["British Shorthair", "british_shorthair", "assets/images/breeds/british_shorthair.png"],
    ["Cornish Rex", "cornish_rex", "assets/images/breeds/cornish_rex.png"],
    ["Devon Rex", "devon_rex", "assets/images/breeds/devon_rex.png"],
    ["Egzotik Shorthair", "egzotik_shorthair", "assets/images/breeds/egzotik_shorthair.png"],
    ["Habeş", "habes", "assets/images/breeds/habes.png"],
    ["Himalayan", "himalayan", "assets/images/breeds/himalayan.png"],
    [
      "Japon Kıvrık Kuyruk",
      "japon_kivrik_kuyruk",
      "assets/images/breeds/japon_kivrik_kuyruk.png"
    ],
    ["Korat", "korat", "assets/images/breeds/korat.png"],
    ["Laperm", "laperm", "assets/images/breeds/laperm.png"],
    ["Maine Coon", "maine_coon", "assets/images/breeds/maine_coon.png"],
    ["Mavi Rus", "mavi_rus", "assets/images/breeds/mavi_rus.png"],
    ["Norveç Orman", "norvec_orman", "assets/images/breeds/norvec_orman.png"],
    ["Ocicat", "ocicat", "assets/images/breeds/ocicat.png"],
    ["Oriental Shorthair", "oriental_shorthair", "assets/images/breeds/oriental_shorthair.png"],
    ["Pixie Bob", "pixie_bob", "assets/images/breeds/pixie_bob.png"],
    ["Ragdoll", "ragdoll", "assets/images/breeds/ragdoll.png"],
    ["Scottish Fold", "scottish_fold", "assets/images/breeds/scottish_fold.png"],
    ["Sfenks", "sfenks", "assets/images/breeds/sfenks.png"],
    ["Siam", "siam", "assets/images/breeds/siam.png"],
    ["Sibirya", "sibirya", "assets/images/breeds/sibirya.png"],
    ["Tekir", "tekir", "assets/images/breeds/tekir.png"],
    ["Tonkinese", "tonkinese", "assets/images/breeds/tonkinese.png"],
    ["Van", "van", "assets/images/breeds/van.png"],
    ["İran", "iran", "assets/images/breeds/iran.png"]
  ];

  for (const [breed_name, slug, avatar_url] of breeds) {
    const exists = await knex("cat_breeds").where({ slug }).first();
    if (exists) {
      await knex("cat_breeds")
        .where({ slug })
        .update({ breed_name, avatar_url, updated_at: knex.fn.now() });
    } else {
      await knex("cat_breeds").insert({
        breed_name,
        slug,
        avatar_url
      });
    }
  }

  // breed_name üzerinden slug eşleştirmesi (migration öncesi elle eklenmiş satırlar)
  for (const [breed_name, slug, avatar_url] of breeds) {
    await knex("cat_breeds")
      .whereNull("slug")
      .andWhere({ breed_name })
      .update({ slug, avatar_url, updated_at: knex.fn.now() });
  }
};
