List<String> admins = [
  'y4w4pWknS7gIBVxKUM3llpbieA92', // matt
  'z5SqbMUvLVb7CfSxQz4OEk9VyDE3', // vanessa
  'XMFwripPojYlcvagoiDEmyoxZyK2', // markus
];

isAdmin(userId) {
  return admins.contains(userId);
}
